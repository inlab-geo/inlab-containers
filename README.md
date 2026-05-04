# InLab Container Stacks

[![build, test and upload](https://img.shields.io/github/actions/workflow/status/inlab-geo/inlab-containers/docker.yml?branch=main&logo=githubactions&style=flat-square&color=31CB00&labelColor=f8f9fa&label=build,%20test%20and%20upload)](https://github.com/inlab-geo/inlab-containers/actions/workflows/docker.yml)

Run InLab CoFI projects without setting up local scientific Python environments.

- CoFI installed
- CoFI examples ready to run
- Full example dependency stack included in the `inlab` image
- Published for `linux/amd64` and `linux/arm64`

## Getting Started

Make sure you have [Docker](https://docs.docker.com/get-docker/) or [Podman](https://podman.io/getting-started/) installed and running.

### Pull and Run

```console
$ docker run -p 8888:8888 inlabgeo/inlab:latest
```

Then open Jupyter Lab in your browser at `http://127.0.0.1:8888`. Enter the token shown in the terminal when prompted.

With Podman:

```console
$ podman run -it -p 8888:8888 inlabgeo/inlab:latest
```

### Build Locally

The full `inlab` target follows the validated Apptainer stack from `inlab-geo/inlab-apptainer/inlab.py313.def`: Fedora 42, native Python 3.13, NumPy 2-compatible packages, and PyGIMLi built from source.

```console
$ docker build --target inlab --file image/Containerfile --tag inlabgeo/inlab:local .
$ docker run -p 8888:8888 inlabgeo/inlab:local
```

Build the lighter CoFI-only image with:

```console
$ docker build --target cofi --file image/Containerfile --tag inlabgeo/cofi:local .
```

Build a specific platform locally:

```console
$ docker buildx build --load --platform linux/amd64 --target inlab --file image/Containerfile --tag inlabgeo/inlab:amd64 .
$ docker buildx build --load --platform linux/arm64 --target inlab --file image/Containerfile --tag inlabgeo/inlab:arm64 .
```

Build a multi-platform image manifest for publishing:

```console
$ docker buildx build --push --platform linux/amd64,linux/arm64 --target inlab --file image/Containerfile --tag inlabgeo/inlab:latest .
```

## Images

[![Image size - cofi](https://img.shields.io/docker/image-size/inlabgeo/cofi?color=87BFFF&label=cofi&logo=docker&style=flat-square&labelColor=f8f9fa)](https://hub.docker.com/r/inlabgeo/cofi)
[![Image size - inlab](https://img.shields.io/docker/image-size/inlabgeo/inlab?color=2667FF&label=inlab&logo=docker&style=flat-square&labelColor=f8f9fa)](https://hub.docker.com/r/inlabgeo/inlab)

image name | inlabgeo/cofi | inlabgeo/inlab
---------- | ------------- | --------------
CoFI       | yes | yes
CoFI examples | | yes
Full examples dependencies | | yes
Jupyter Lab | | yes

## Build Inputs

`versions.txt` controls the source versions used by automated builds:

- `COFI_VERSION`: PyPI version of `cofi`
- `COFI_EXAMPLES_VERSION`: Git ref for `inlab-geo/cofi-examples`

The Docker build also accepts these optional arguments:

- `COFI_INSTALL_SOURCE=pypi|git`: install CoFI from PyPI or GitHub.
- `COFI_REF`: Git ref used when `COFI_INSTALL_SOURCE=git`.
- `COFI_EXAMPLES_REPO`: examples repository URL, defaulting to `https://github.com/inlab-geo/cofi-examples.git`.

For a detailed explanation of the repository layout, image stages, CI workflow, and runtime behavior, see [docs/how-it-works.md](docs/how-it-works.md).

## Validation

The full notebook validation command is available inside the image:

```console
$ docker run --rm inlabgeo/inlab:local bash -lc 'python tools/run_notebooks/run_notebooks.py all'
```

The runner writes `tools/run_notebooks/notebook_execution_report.md` inside the container and stores failed notebooks under `tools/run_notebooks/failed_notebooks/`.

## More References

- [inlab-geo/inlab-apptainer](https://github.com/inlab-geo/inlab-apptainer)
- [Apptainer](https://apptainer.org/)
- [Jupyter Docker Stacks quick start](https://github.com/jupyter/docker-stacks/tree/main#quick-start)

## Acknowledgement

This repository was originally generated from the [Jupyter Docker Stacks cookiecutter](https://github.com/jupyter/cookiecutter-docker-stacks).
