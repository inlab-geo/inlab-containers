# syntax=docker/dockerfile:1

ARG MAMBA_DOCKERFILE_ACTIVATE=1

FROM mambaorg/micromamba:1.4.0 as base
ARG INLAB_USER=inlab \
    INLAB_USER_ID=1000 \
    INLAB_USER_GID=1000 \
    MAMBA_DOCKERFILE_ACTIVATE
USER root
RUN usermod "--login=$INLAB_USER" "--home=/home/$INLAB_USER" \
        --move-home "-u $INLAB_USER_ID" "$MAMBA_USER" \
    && groupmod "--new-name=$INLAB_USER" \
             "-g $INLAB_USER_GID" "$MAMBA_USER" \
    && echo "$INLAB_USER" > "/etc/arg_mamba_user" \
    && micromamba install --quiet --yes --name base --channel conda-forge \
        python=3.9 jupyterlab nodejs yarn git \
    && micromamba clean --all --quiet --yes
ENV MAMBA_USER=$INLAB_USER \
    INLAB_USER=$INLAB_USER \
    PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"
WORKDIR $HOME
EXPOSE 8888
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh", "jupyter-lab"]

FROM base AS cofi
ARG MAMBA_DOCKERFILE_ACTIVATE
RUN python -m pip install --no-cache-dir -U cofi

FROM base AS espresso
ARG MAMBA_DOCKERFILE_ACTIVATE
RUN python -m pip install --no-cache-dir -U geo-espresso

FROM cofi AS cofi_n_espresso
ARG MAMBA_DOCKERFILE_ACTIVATE
RUN python -m pip install --no-cache-dir -U geo-espresso

FROM cofi_n_espresso AS inlab
ARG MAMBA_DOCKERFILE_ACTIVATE
RUN echo ${PATH}
RUN git clone https://github.com/inlab-geo/cofi-examples.git
RUN micromamba install --quiet --yes --name base \
        --channel gimli --channel conda-forge \
        simpeg pygimli
