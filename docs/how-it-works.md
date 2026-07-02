# How This Repository Works

This repository builds and publishes Docker images for InLab CoFI workflows. The refreshed structure keeps two supported image targets:

- `cofi`: a smaller Ubuntu/Python image for users who need CoFI and its core solver stack.
- `inlab`: the full examples image, aligned with the validated `inlab.py313.def` Apptainer build from `inlab-geo/inlab-apptainer`.

Both targets are defined in `image/Containerfile`. The CI workflow builds each target explicitly, which avoids accidentally tagging the final stage as every image.

## Repository Layout

- `image/Containerfile` is the source of truth for the Docker build.
- `image/scripts/install-cofi.sh` installs CoFI and the core inference helper packages.
- `image/scripts/install-pygimli.sh` builds PyGIMLi from source using the Ubuntu 24.04 system toolchain.
- `image/scripts/install-inlab-python-packages.sh` installs the full examples dependency stack.
- `image/build.sh` is the local helper script for platform-aware builds.
- `versions.txt` records the CoFI package version and CoFI examples Git ref used by automated builds.
- `.github/workflows/docker.yml` builds, tests, tags, and publishes images.
- `.github/workflows/versions.yml` opens automated pull requests when the tracked CoFI inputs change.
- `tests/` contains container smoke tests and repository hygiene checks.

## Image Stage Flow

The Dockerfile starts from `ubuntu:24.04` (LTS, supported until April 2029), ported from the Fedora-based Apptainer validation image. The shared `ubuntu-python` stage installs the native Ubuntu build toolchain and Python 3.12:

- GCC, G++, GFortran, CMake, CastXML, Clang, OpenBLAS, LAPACK, SuiteSparse, GEOS, PROJ, Boost, and related headers.
- Python 3.12 and development headers.
- A `jovyan` runtime user for Jupyter Lab.
- Initial Python build tooling plus NumPy, SciPy, and Matplotlib.

The `cofi` stage installs the lightweight CoFI runtime. By default it installs CoFI from PyPI using `COFI_VERSION`; it can also install from GitHub when `COFI_INSTALL_SOURCE=git` and `COFI_REF` is supplied.

The `inlab` stage follows the Apptainer build order closely:

1. Clone and build GIMLi/PyGIMLi from source under `/opt/gimli`.
2. Manually build Triangle and Boost 1.87.0 for the PyGIMLi build. Triangle is compiled with its old `LINUX` FPU-control block only on x86, because that block can raise `SIGFPE` from `exactinit()` on ARM64 and kill PyGIMLi notebooks.
3. Register `/opt/gimli/build/lib` with `ldconfig`, add `/opt/gimli/gimli` as a Python site path, and install PyGIMLi in editable mode without dependencies so package metadata is available to notebook watermark cells.
4. Install the Python packages used by the examples, including ObsPy from GitHub and InLab packages from GitHub.
5. Install `pysurf96` from `inlab-geo/pysurf96`; on ARM builds the script strips unsupported `-m64` flags before installation.
6. Install CoFI, Jupyter Lab, notebook execution tooling, and the Python kernel.
7. Clone `inlab-geo/cofi-examples` into `/home/jovyan/cofi-examples` and optionally check out `COFI_EXAMPLES_VERSION`.

The final image starts Jupyter Lab on port `8888`, with `/home/jovyan/cofi-examples` as the working directory.

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
- `COFI_EXAMPLES_VERSION` controls the Git ref checked out in the full `inlab` image.

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

The full image defaults `JOBLIB_MULTIPROCESSING=0` so BayesBay notebooks use joblib's threading fallback instead of spawning many `loky` worker processes. This avoids container kernel deaths seen in the surface-wave tomography example while still allowing users to override the environment variable when they intentionally want process-based parallelism.

## Local Validation

The expected local validation sequence is:

```console
docker build --target cofi -f image/Containerfile -t inlabgeo/cofi:refresh .
docker build --target inlab -f image/Containerfile -t inlabgeo/inlab:refresh .
python3 tests/test_removed_references.py
git diff --check
docker run --rm inlabgeo/cofi:refresh bash -lc 'python -c "import cofi, numpy, scipy; print(\"ok\")"'
docker run --rm inlabgeo/inlab:refresh bash -lc 'python -c "import cofi, numpy, scipy, matplotlib, pygimli, pysurf96, pyfm2d, pyrf96, pyhk, smt, seislib, astroquery, discretize; print(\"ok\")"'
docker run --rm inlabgeo/inlab:refresh bash -lc 'jupyter lab --version && test -d "$HOME/cofi-examples"'
```

The full notebook suite is the slower integration test:

```console
docker run --rm inlabgeo/inlab:refresh bash -lc 'python tools/run_notebooks/run_notebooks.py all'
```

The target expectation is fewer than five failed notebooks when CoFI and CoFI examples are mutually compatible.
