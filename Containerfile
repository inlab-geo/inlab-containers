# syntax=docker/dockerfile:1

FROM jupyter/scipy-notebook:latest as base

FROM base AS cofi
RUN pip install --no-cache-dir -U cofi
WORKDIR /home/firedrake

FROM base AS espresso
RUN pip install --no-cache-dir -U geo-espresso

FROM cofi AS cofi_n_espresso
RUN pip install --no-cache-dir -U geo-espresso

FROM cofi_n_espresso AS inlab
RUN git clone https://github.com/inlab-geo/cofi-examples.git
RUN mamba install -y -n base -c gimli pygimli; \
    mamba install -y -n base simpeg; \
    mamba clean --all --yes
