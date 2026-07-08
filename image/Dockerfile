# syntax=docker/dockerfile:1

# build with --platform=linux/amd64 if using a silicon Mac

FROM python:3.12-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /build

# System deps for compiled packages, including pyGIMLi
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    g++ \
    git \
    gfortran \
    python3-dev \
    libopenblas-dev \
    liblapack-dev \
    libomp-dev \
    && rm -rf /var/lib/apt/lists/*

# Create an isolated environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

RUN python -m pip install --upgrade pip wheel setuptools

# Install Python deps first so this layer is cached well
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt


ARG COFI_EXAMPLES_REPO="https://github.com/inlab-geo/cofi-examples.git"
ARG COFI_EXAMPLES_VERSION="latest"


# Copy notebooks last so edits do not invalidate the dependency layer
RUN git clone "${COFI_EXAMPLES_REPO}" /cofi-examples \
 && if [[ "${COFI_EXAMPLES_VERSION}" != "latest" ]]; then \
      git -C /cofi-examples checkout "${COFI_EXAMPLES_VERSION}"; \
    fi 

# If pygimli is in requirements.txt, pip will try to install it here.
# If your case really needs the source build path, do it explicitly here,
# following pyGIMLi's out-of-source cmake approach.

FROM python:3.12-slim AS runtime

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /cofi-examples

RUN apt-get update && apt-get install -y --no-install-recommends \
    libopenblas0 \
    liblapack3 \
    libomp5 \
    && rm -rf /var/lib/apt/lists/*
    
ARG NB_UID=1000
ARG NB_GID=1000

RUN  if getent passwd "${NB_UID}" >/dev/null; then userdel -r "$(getent passwd "${NB_UID}" | cut -d: -f1)"; fi \
 && if getent group "${NB_GID}" >/dev/null; then groupdel "$(getent group "${NB_GID}" | cut -d: -f1)"; fi \
 && groupadd --gid "${NB_GID}" jovyan \
 && useradd --create-home --shell /bin/bash --uid "${NB_UID}" --gid "${NB_GID}" jovyan 

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder --chown=${NB_UID}:${NB_GID} /cofi-examples/cofi-paper /home/jovyan/cofi-examples/cofi-paper
COPY --from=builder --chown=${NB_UID}:${NB_GID} /cofi-examples/examples /home/jovyan/cofi-examples/examples
COPY --from=builder --chown=${NB_UID}:${NB_GID} /cofi-examples/data /home/jovyan/cofi-examples/data
COPY --from=builder --chown=${NB_UID}:${NB_GID} /cofi-examples/tutorials /home/jovyan/cofi-examples/tutorials
COPY --from=builder --chown=${NB_UID}:${NB_GID} /cofi-examples/theory /home/jovyan/cofi-examples/theory

ENV PATH="/opt/venv/bin:${PATH}"

COPY image/scripts/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

USER jovyan
WORKDIR /home/jovyan/cofi-examples
EXPOSE 8888 2718

CMD ["/usr/local/bin/start.sh"]
