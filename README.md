# InLab Container Stacks

[![build, test and upload](https://img.shields.io/github/actions/workflow/status/inlab-geo/inlab-containers/docker.yml?branch=main&logo=githubactions&style=flat-square&color=31CB00&labelColor=f8f9fa&label=build,%20test%20and%20upload)](https://github.com/inlab-geo/inlab-containers/actions/workflows/docker.yml)

Wanna run InLab projects without the hassle of setting up environments or deploy it to the cloud? This is for you!

- CoFI installed ✅
- Espresso installed ✅
- CoFI examples ready to run ✅

## Getting Started

Firstly, make sure you have [Docker](https://docs.docker.com/get-docker/) 
(or [Podman](https://podman.io/getting-started/), a Docker alternative) 
installed and running. 

### Pull & run (Recommended)

```console
$ docker run -p 8888:8888 inlabgeo/inlab:latest
```

Then open the Juptyer Lab with your browswer at: `https://127.0.0.1:8888`. Enter the token as shown in the terminal into your browser when prompted.

If you prefer to use podman the command is

```
podman run -it -p 8888:8888 inlabgeo/inlab:latest
```

### Build your own (Optional)

```console
$ docker build --file image/Containerfile --tag inlab .
$ docker run -p 8888:8888 inlab
```

The Jupyter Lab should then be accessible through your browser locally.

## Images

[![Image size - espresso](https://img.shields.io/docker/image-size/inlabgeo/espresso?color=ADD7F6&label=espresso&logo=docker&style=flat-square&labelColor=f8f9fa)](https://hub.docker.com/r/inlabgeo/espresso)
[![Image size - cofi](https://img.shields.io/docker/image-size/inlabgeo/cofi?color=87BFFF&label=cofi&logo=docker&style=flat-square&labelColor=f8f9fa)](https://hub.docker.com/r/inlabgeo/cofi)
[![Image size - cofi_n_espresso](https://img.shields.io/docker/image-size/inlabgeo/cofi_n_espresso?color=3F8EFC&label=cofi_n_espresso&logo=docker&style=flat-square&labelColor=f8f9fa)](https://hub.docker.com/r/inlabgeo/cofi_n_espresso)
[![Image size - inlab](https://img.shields.io/docker/image-size/inlabgeo/inlab?color=2667FF&label=inlab&logo=docker&style=flat-square&labelColor=f8f9fa)](https://hub.docker.com/r/inlabgeo/inlab)

The above instructions are for the default InLab image `inlabgeo/inlab`.

If you'd like to run a more lightweight image for specific purposes, here's a lookup table:

image name | inlabgeo/espresso | inlabgeo/cofi | inlabgeo/cofi_n_espresso | inlabgeo/inlab
---------- | ------------- | ----------------- | ------------------------ | --------------
CoFI       | | ✅ | ✅ | ✅ 
Espresso   | ✅ | | ✅ | ✅ 
CoFI Examples | | | | ✅ 

## More references

The InLab containers are built based on the Jupyter Docker Stacks, and we inherit the 
entry point created by the Jupyter team. 

If you have any further questions about running
the containers, we kindly recommend referring to the
[Getting started guide](https://github.com/jupyter/docker-stacks/tree/main#quick-start)
provided by the Jupyter team.

## Acknowledgement

This infrastructure is genereated by the 
[Jupyter Docker Stacks cookiecutter](https://github.com/jupyter/cookiecutter-docker-stacks).
