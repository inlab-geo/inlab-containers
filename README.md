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

The `inlab` image also serves the `cofi-paper` marimo notebooks. Add `-p 2718:2718` to either
command above to reach them at `http://127.0.0.1:2718`.

### Build Locally

The full `inlab` target is adapted from the validated Apptainer stack in `inlab-geo/inlab-apptainer/inlab.py313.def`, ported to Ubuntu 24.04 LTS (supported until April 2029) with native Python 3.12, NumPy 2-compatible packages, and PyGIMLi installed as a pinned prebuilt pip wheel on `amd64` / built from source on `arm64` (see `docs/how-it-works.md`).

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

PyGIMLi installs differently per architecture (prebuilt wheel on `amd64`, from source on
`arm64`, both pinned to the same version), so the two `inlab` image sizes differ
substantially even though their package versions match.

## More References

The InLab containers are built based on the Jupyter Docker Stacks, and we inherit the entry point created by the Jupyter team.
If you have any further questions about running the containers, we kindly recommend referring to the Getting started guide provided by the Jupyter team.

- [inlab-geo/inlab-apptainer](https://github.com/inlab-geo/inlab-apptainer)
- [Apptainer](https://apptainer.org/)
- [Jupyter Docker Stacks quick start](https://github.com/jupyter/docker-stacks/tree/main#quick-start)

## Acknowledgement

This repository was originally generated from the [Jupyter Docker Stacks cookiecutter](https://github.com/jupyter/cookiecutter-docker-stacks).
