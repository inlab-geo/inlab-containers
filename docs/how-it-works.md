# How This Repository Works

This repository builds and publishes Docker images for InLab CoFI workflows. The refreshed structure keeps two supported image targets:

- `cofi`: a smaller Ubuntu/Python image with CoFI, its core solver stack, and the `cofi-paper` notebooks served via marimo — no PyGIMLi, no full examples tree, no Jupyter.
- `inlab`: the full examples image, aligned with the validated `inlab.py313.def` Apptainer build from `inlab-geo/inlab-apptainer`.

Both targets are defined in `image/Containerfile`. The CI workflow builds each target explicitly, which avoids accidentally tagging the final stage as every image.

## Repository Layout

- `image/Containerfile` is the source of truth for the Docker build.
- `image/scripts/install-cofi.sh` pins a CPU-only PyTorch build (CoFI depends on `torch>=2.0.0`, and PyPI's default Linux wheel drags in the full NVIDIA CUDA toolkit — several GB unusable in a plain container), then installs CoFI and the core inference helper packages.
- `image/scripts/install-seislib.sh` builds seislib from source, stripping its hardcoded `-march=native` flag so the compiled extension stays portable across CPUs.
- `image/scripts/install-cofi-paper-deps.sh` installs the extra packages `cofi-paper`'s notebooks need (`cofi-examples/cofi-paper/requirements.txt`), on top of `install-seislib.sh`.
- `image/scripts/install-pygimli.sh` builds PyGIMLi from source using the Ubuntu 24.04 system toolchain — used everywhere except `amd64`, where `image/scripts/install-pygimli-pip.sh` installs the prebuilt `pygimli`/`pgcore` PyPI wheels instead (`pgcore`, PyGIMLi's compiled core, ships `manylinux` wheels for x86_64 only — no `aarch64` wheel or sdist exists). Both scripts are pinned to the same `PYGIMLI_VERSION` (an `ARG` default in `image/Containerfile`, not tracked in `versions.txt`), so the two architectures ship the same PyGIMLi release even though they get there differently.
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

PyGIMLi's heavy C++ toolchain (Boost, SuiteSparse, OpenBLAS, CastXML, CppUnit, etc.) is **not** in this shared stage — it's installed later, only in the `inlab` stage, and only when building for `arm64` (the pip-installed `amd64` path needs none of it), so `cofi` never carries it at all.

The `cofi` stage builds the lightweight CoFI + `cofi-paper` runtime:

1. Install CoFI (`install-cofi.sh`). By default from PyPI using `COFI_VERSION`; from GitHub when `COFI_INSTALL_SOURCE=git` and `COFI_REF` is supplied.
2. Sparse-clone `inlab-geo/cofi-examples` into `/home/jovyan/cofi-examples`, checking out only the `cofi-paper` directory (`git clone --filter=blob:none --no-checkout` + `git sparse-checkout set --cone cofi-paper`), then check out `COFI_EXAMPLES_VERSION`. This avoids downloading the rest of the examples repo (`examples/`, `tutorials/`, `theory/`, etc.).
3. Install `cofi-paper`'s remaining notebook dependencies (`install-cofi-paper-deps.sh`): seislib (via `install-seislib.sh`) plus everything in `cofi-examples/cofi-paper/requirements.txt` — h5py, arviz, Cartopy, cmcrameri, marimo, nbformat, and pyfm2d. Packages already installed in step 1 (CoFI, BayesBay, mealpy, NumPy/SciPy/Matplotlib) are left alone since pip skips already-satisfied unpinned requirements.

The final `cofi` image runs as `jovyan`, with `/home/jovyan/cofi-examples/cofi-paper` as the working directory, and starts `marimo edit` on port `2718` so a reviewer can open and run the paper's notebooks directly.

The `inlab` stage builds `FROM cofi` and follows the Apptainer build order closely. It switches back to `USER root` first (needed for apt-get and, on non-amd64 architectures, the PyGIMLi build), then PyGIMLi installation forks by architecture (both branches on `uname -m`, matching the Triangle-CFLAGS and pysurf96 `-m64` checks elsewhere in this repo):

**On `linux/amd64`:** `pgcore` (PyGIMLi's compiled core) ships a prebuilt `manylinux` wheel for x86_64 that bundles its own Boost, SuiteSparse, OpenBLAS, and GIMLi shared libraries via `auditwheel`. The apt-get step below is skipped entirely, and `install-pygimli-pip.sh` just runs `pip install "pygimli==${PYGIMLI_VERSION}" "pgcore==${PYGIMLI_VERSION}"` — a self-contained ~90MB install with no system toolchain required.

**On `linux/arm64` (and any other architecture):** `pgcore` publishes no `aarch64` wheel and no sdist, so PyGIMLi is still built from source, exactly as before, now pinned to the same `PYGIMLI_VERSION` via a `git clone --branch "v${PYGIMLI_VERSION}"`:

1. apt-get installs the PyGIMLi-only system packages (Boost, SuiteSparse, OpenBLAS, CastXML, CppUnit, libedit, plus `pandoc`/`clang` for GIMLi's Sphinx docs and `vim`/`subversion`/`mercurial`).
2. Clone and build GIMLi/PyGIMLi from source under `/opt/gimli`.
3. Manually build Triangle and Boost 1.87.0 for the PyGIMLi build. Triangle is compiled with its old `LINUX` FPU-control block only on x86, because that block can raise `SIGFPE` from `exactinit()` on ARM64 and kill PyGIMLi notebooks (moot on the amd64/pip path, which never runs this).
4. Register `/opt/gimli/build/lib` with `ldconfig`, add `/opt/gimli/gimli` as a Python site path, and install PyGIMLi in editable mode without dependencies so package metadata is available to notebook watermark cells (this step is itself skipped on `amd64`, since `/opt/gimli/gimli` never exists there).

Either way, the stage then:

5. Installs the remaining example dependencies not already inherited from `cofi` (`install-inlab-python-packages.sh`): numba, ObsPy, pyrf96, pyhk, pysurf96 (with the ARM `-m64` fix), PyP223, SimPEG stack, Jupyter Lab, notebook execution tooling, and the Python kernel.
6. Widens the `cofi` stage's sparse clone to the full `cofi-examples` tree with `git sparse-checkout disable` — this reuses the same local repo (and its already-checked-out `COFI_EXAMPLES_VERSION` commit) instead of re-cloning, fetching only the additional blobs it needs.

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

Because of the PyGIMLi packaging fork described above, the `inlab` image is substantially smaller (and faster to build) on `linux/amd64` than on `linux/arm64`, even though both carry the same package set and the same pinned PyGIMLi version.

## Build Inputs

`versions.txt` is read by GitHub Actions and converted into Docker build arguments:

- `COFI_VERSION` controls the PyPI release installed in the images.
- `COFI_EXAMPLES_VERSION` controls the Git ref checked out for `cofi-paper` in the `cofi` image, and (by extension, since `inlab` builds `FROM cofi` and just widens the same checkout) for the full examples tree in `inlab` too.

The Dockerfile also accepts:

- `COFI_INSTALL_SOURCE=pypi|git`
- `COFI_REF`, used when installing CoFI from GitHub
- `COFI_EXAMPLES_REPO`, used when testing a fork of the examples repository
- `PYGIMLI_VERSION`, which drives both the pip version pin (`amd64`) and the git tag checkout (`arm64`, as `v${PYGIMLI_VERSION}`) described above. Unlike the inputs above, it isn't read from `versions.txt` — it's a plain `ARG PYGIMLI_VERSION` default in `image/Containerfile` itself, kept out of `versions.txt` deliberately so that file stays scoped to the CoFI inputs it already tracks. Bumping it means editing that one line directly; it won't be picked up by the `versions.yml` auto-update workflow.

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

The full notebook suite is the slower integration test:

```console
docker run --rm inlabgeo/inlab:refresh bash -lc 'python tools/run_notebooks/run_notebooks.py all'
```

The target expectation is fewer than five failed notebooks when CoFI and CoFI examples are mutually compatible.
