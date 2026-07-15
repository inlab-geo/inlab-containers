# How This Repository Works

This repository builds and publishes Docker images for InLab CoFI workflows. The refreshed structure keeps two supported image targets:

- `cofi`: a smaller Ubuntu/Python image with CoFI, its core solver stack, and the `cofi-paper` notebooks served via marimo — no PyGIMLi, no full examples tree, no Jupyter.
- `inlab`: the full examples image, aligned with the validated `inlab.py313.def` Apptainer build from `inlab-geo/inlab-apptainer`.

Both targets are defined in `image/Containerfile`. The CI workflow builds each target explicitly, which avoids accidentally tagging the final stage as every image.

## Repository Layout

- `image/Containerfile` is the source of truth for the Docker build.
- `image/scripts/install-cofi.sh` pins a CPU-only PyTorch build below `2.13` (CoFI depends on `torch>=2.0.0`; PyPI's default Linux wheel drags in the full NVIDIA CUDA toolkit — several GB unusable in a plain container — and `torch==2.13.0`'s arm64 CPU wheel fails to import at all, `undefined symbol: sbgemm_`), then installs CoFI and the core inference helper packages.
- `image/scripts/install-seislib.sh` builds seislib from source, stripping its hardcoded `-march=native` flag so the compiled extension stays portable across CPUs.
- `image/scripts/install-cofi-paper-deps.sh` installs the extra packages `cofi-paper`'s notebooks need (`cofi-examples/cofi-paper/requirements.txt`), on top of `install-seislib.sh`.
- `image/scripts/install-pygimli.sh` builds PyGIMLi from source using the Ubuntu 24.04 system toolchain.
- `image/scripts/install-inlab-python-packages.sh` installs the remaining full examples dependency stack not already covered by the `cofi` stage.
- `image/build.sh` is the local helper script for platform-aware builds.
- `versions.txt` records the CoFI package version and CoFI examples Git ref used by automated builds.
- `.github/workflows/docker.yml` builds, tests, tags, and publishes images.
- `.github/workflows/versions.yml` opens automated pull requests when the tracked CoFI inputs change.
- `tests/` contains container smoke tests and repository hygiene checks.

## Image Stage Flow

The Dockerfile starts from `ubuntu:24.04` (LTS, supported until April 2029), ported from the Fedora-based Apptainer validation image. The shared `ubuntu-python` stage stays deliberately lean, installing only what *both* `cofi` and `inlab` need:

- GCC, G++, GFortran, CMake, Ninja, and related build tooling.
- GEOS and PROJ headers (Cartopy) and zlib.
- Python 3.12 and development headers.
- A `jovyan` runtime user, shared by both images.
- Initial Python build tooling plus NumPy, SciPy, and Matplotlib.

PyGIMLi's heavy C++ toolchain (Boost, SuiteSparse, OpenBLAS, CastXML, CppUnit, etc.) is **not** in this shared stage — it's installed later, only in the `inlab` stage, so `cofi` never carries it.

### Fetching cofi-examples: the `cofi-examples-src` build-only stage

`cofi-examples-src` is a build-only stage (never a build `--target`, never published) that resolves `COFI_EXAMPLES_VERSION` to a GitHub archive URL — `<repo>/archive/<ref>.tar.gz`, where `<ref>` is `main` when `COFI_EXAMPLES_VERSION=latest`, otherwise the pinned commit/tag as-is — and downloads it with `curl | tar`. Since the version is already pinned to an exact commit, a plain archive download carries the same content as a git clone would, but with none of git's history metadata: no `.git` ever exists, so there's nothing to strip later. (The previous `git clone --filter=blob:none` approach's `.git` directory measured 151MB — almost entirely commit/tree history, not working-tree content.)

That single archive is snapshotted into two plain (non-git) directories inside the same stage:
- `/tmp/cofi-view`: just `cofi-paper/` plus `LICENCE` and `index.ipynb`.
- `/tmp/inlab-view`: the full tree, minus `tools/`, `envs/`, `.github/`, `README.md`, `CONTRIBUTING.md`, `examples/pygimli_dcip/archived/`, `examples/pygimli_ert/archived/`, and `examples/more_scripts/`. (`tools/` and `envs/` are cofi-examples' own CI/validation scripts and non-Docker conda/pip setup files — irrelevant once every dependency is already installed in the image; the `archived/` notebooks and `more_scripts/` were confirmed broken/out of scope during notebook testing — see `notebook-test-report.md`.)

The `cofi` and `inlab` runtime stages then `COPY --from=cofi-examples-src --chown=jovyan:jovyan` the relevant view into `/home/jovyan/cofi-examples`. Because `COPY --from=` only copies the resolved final filesystem of the source stage — not its layer history — none of `cofi-examples-src`'s intermediate layers (including the full, unpruned archive extraction) ever become part of either shipped image.

The `cofi` stage builds the lightweight CoFI + `cofi-paper` runtime:

1. Install CoFI (`install-cofi.sh`). By default from PyPI using `COFI_VERSION`; from GitHub when `COFI_INSTALL_SOURCE=git` and `COFI_REF` is supplied.
2. `COPY --from=cofi-examples-src /tmp/cofi-view /home/jovyan/cofi-examples` — just `cofi-paper/` (plus `LICENCE`/`index.ipynb`), no `.git`, no full examples tree.
3. Install `cofi-paper`'s remaining notebook dependencies (`install-cofi-paper-deps.sh`): seislib (via `install-seislib.sh`) plus everything in `cofi-examples/cofi-paper/requirements.txt` — h5py, arviz, Cartopy, cmcrameri, marimo, nbformat, and pyfm2d. Packages already installed in step 1 (CoFI, BayesBay, mealpy, NumPy/SciPy/Matplotlib) are left alone since pip skips already-satisfied unpinned requirements.

The final `cofi` image runs as `jovyan`, with `/home/jovyan/cofi-examples/cofi-paper` as the working directory, and starts `marimo edit` on port `2718` so a reviewer can open and run the paper's notebooks directly.

The `inlab` stage builds `FROM cofi` and follows the Apptainer build order closely. It switches back to `USER root` first (needed for apt-get and the PyGIMLi build), then:

1. apt-get installs system packages, branching on `uname -m`. PyGIMLi's compiled backend (`pgcore`) only ships `manylinux_x86_64` wheels on PyPI, so on `x86_64`/`amd64` only `vim` is installed and PyGIMLi comes from a prebuilt wheel; everywhere else (`arm64`, with no `manylinux_aarch64` wheel available) the full source-build toolchain is installed too (Boost, SuiteSparse, OpenBLAS, CastXML, CppUnit, libedit, plus `pandoc`/`clang` for GIMLi's Sphinx docs and `subversion`/`mercurial`).
2. Install PyGIMLi (same `uname -m` branch): `install-pygimli-pip.sh` runs `pip install pygimli` on amd64; `install-pygimli.sh` clones and builds GIMLi/PyGIMLi from source under `/opt/gimli` everywhere else.
3. On the source-build path only: manually build Triangle and Boost 1.87.0 for the PyGIMLi build. Triangle is compiled with its old `LINUX` FPU-control block only on x86, because that block can raise `SIGFPE` from `exactinit()` on ARM64 and kill PyGIMLi notebooks (moot on the amd64/pip path, which never runs this).
4. On the source-build path only: register `/opt/gimli/build/lib` with `ldconfig`, add `/opt/gimli/gimli` as a Python site path, and install PyGIMLi in editable mode without dependencies so package metadata is available to notebook watermark cells. The pip path skips all of this — `pygimli`/`pgcore` are already normal site-packages installs.
5. Install the remaining example dependencies not already inherited from `cofi` (`install-inlab-python-packages.sh`): numba, ObsPy, pyrf96, pyhk, pysurf96 (with the ARM `-m64` fix), PyP223, SimPEG stack, Jupyter Lab, notebook execution tooling, and the Python kernel.
6. `COPY --from=cofi-examples-src /tmp/inlab-view /home/jovyan/cofi-examples` — overwrites the `cofi-paper`-only tree inherited from `FROM cofi` with the fuller, pre-pruned view (`examples/`, `data/`, `theory/`, `tutorials/`, still no `.git`/`tools/`/`envs/`/`.github/`/archived notebooks).

The final image starts both Jupyter Lab (port `8888`) and marimo (port `2718`, serving `cofi-paper`), with `/home/jovyan/cofi-examples` as the working directory.

## Architecture Support

The Dockerfile is intended to build for:

- `linux/amd64`
- `linux/arm64`

The local build helper defaults to the host architecture:

```console
bash image/build.sh
```

Set `PLATFORMS` for a specific architecture:

```console
PLATFORMS=linux/arm64 TARGETS=inlab bash image/build.sh
```

Build and push a multi-platform manifest with Docker Buildx:

```console
PLATFORMS=linux/amd64,linux/arm64 PUSH=true TARGETS=inlab bash image/build.sh
```

GitHub Actions uses Buildx and QEMU. Pull requests build and test the native CI platform image; pushes to `main` publish multi-platform `linux/amd64` and `linux/arm64` manifests.

## Build Inputs

`versions.txt` is read by GitHub Actions and converted into Docker build arguments:

- `COFI_VERSION` controls the PyPI release installed in the images.
- `COFI_EXAMPLES_VERSION` controls the Git ref checked out for `cofi-paper` in the `cofi` image, and (by extension, since `inlab` builds `FROM cofi` and just widens the same checkout) for the full examples tree in `inlab` too.

The Dockerfile also accepts:

- `COFI_INSTALL_SOURCE=pypi|git`
- `COFI_REF`, used when installing CoFI from GitHub
- `COFI_EXAMPLES_REPO`, used when testing a fork of the examples repository

## CI Workflow

`.github/workflows/docker.yml` runs on relevant pull requests, pushes to `main`, and manual dispatches.

The workflow does the following:

1. Checks out the repository.
2. Sets up Python test dependencies.
3. Sets up QEMU and Docker Buildx.
4. Reads `versions.txt`.
5. Runs the retired-package reference guard.
6. Builds `inlabgeo/cofi:latest` for `linux/amd64` and loads it locally.
7. Builds `inlabgeo/inlab:latest` for `linux/amd64` and loads it locally.
8. Runs `pytest` against the local image.
9. On `main`, builds and pushes multi-platform manifests for `linux/amd64` and `linux/arm64`.

The explicit `--target` flags are important. Without them, Docker would build the final stage and the workflow could repeatedly tag the same image under multiple names.

`.github/workflows/versions.yml` runs on a schedule and on manual dispatch. It checks the latest CoFI PyPI release and the latest `cofi-examples` main commit, writes those values to `versions.txt`, and opens a pull request with the update.

## Runtime Behavior

Users run the published image with:

```console
docker run -p 8888:8888 inlabgeo/inlab:latest
```

Jupyter Lab starts and prints an access token. The container listens on port `8888`; the user maps that port to the host and opens `http://127.0.0.1:8888`.

Because the working directory is `/home/jovyan/cofi-examples`, Jupyter opens directly at the examples tree. Users do not need to install CoFI, clone examples, compile native extensions, or tune local library paths.

The `cofi` image is run the same way but on port `2718`:

```console
docker run -p 2718:2718 inlabgeo/cofi:latest
```

This starts `marimo edit` directly on `cofi-paper`, so a reviewer gets the paper's notebooks without pulling PyGIMLi, the full examples tree, or Jupyter.

Both images default `JOBLIB_MULTIPROCESSING=0` so BayesBay notebooks use joblib's threading fallback instead of spawning many `loky` worker processes. This avoids container kernel deaths seen in the surface-wave tomography example and in `cofi-paper`'s educator notebook, while still allowing users to override the environment variable when they intentionally want process-based parallelism.

## Local Validation

The expected local validation sequence is:

```console
docker build --target cofi -f image/Containerfile -t inlabgeo/cofi:refresh .
docker build --target inlab -f image/Containerfile -t inlabgeo/inlab:refresh .
python3 tests/test_removed_references.py
git diff --check
docker run --rm inlabgeo/cofi:refresh bash -lc 'python -c "import cofi, numpy, scipy, h5py, arviz, seislib, cartopy, cmcrameri, pyfm2d, marimo; print(\"ok\")"'
docker run --rm inlabgeo/cofi:refresh bash -lc 'ls "$HOME/cofi-examples"'  # should list only cofi-paper
docker run --rm inlabgeo/inlab:refresh bash -lc 'python -c "import cofi, numpy, scipy, matplotlib, pygimli, pysurf96, pyfm2d, pyrf96, pyhk, smt, seislib, astroquery, discretize; print(\"ok\")"'
docker run --rm inlabgeo/inlab:refresh bash -lc 'jupyter lab --version && test -d "$HOME/cofi-examples"'
```

The full notebook suite is the slower integration test. `cofi-examples`' own `tools/run_notebooks/run_notebooks.py` is **not** shipped in the image (see "Fetching cofi-examples" above), so run notebooks directly via `papermill`/`marimo export` instead, e.g.:

```console
docker run --rm inlabgeo/inlab:refresh bash -lc \
  'papermill /home/jovyan/cofi-examples/examples/xray_tomography/xray_tomography.ipynb /tmp/out.ipynb -k python3'
```

Both `papermill` and `marimo` are already installed in the image, so no extra setup is needed to run either notebook format this way.
