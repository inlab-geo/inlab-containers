#!/bin/bash
set -euxo pipefail

python -m pip install \
    numba \
    llvmlite \
    "seaborn>=0.13" \
    cmcrameri \
    shapely \
    cartopy

python -m pip install git+https://github.com/obspy/obspy.git
python -m pip install seislib astroquery marimo

python -m pip install git+https://github.com/inlab-geo/pyfm2d
python -m pip install git+https://github.com/inlab-geo/pyrf96
python -m pip install git+https://github.com/inlab-geo/pyhk

PYSURF96_SRC=$(mktemp -d)
trap 'rm -rf "${PYSURF96_SRC}"' EXIT
git clone --depth 1 https://github.com/inlab-geo/pysurf96 "${PYSURF96_SRC}/pysurf96"
if [[ "$(uname -m)" == "aarch64" || "$(uname -m)" == "arm64" ]]; then
    find "${PYSURF96_SRC}/pysurf96" \
        -type f \( -name "*.py" -o -name "meson.build" -o -name "CMakeLists.txt" \) \
        -exec sed -i 's/-m64//g' {} +
fi
python -m pip install "${PYSURF96_SRC}/pysurf96"

python -m pip install git+https://github.com/JuergHauser/PyP223.git

python -m pip install \
    smt \
    discretize \
    simpeg \
    portalocker \
    ipywidgets \
    tqdm \
    pandas \
    sympy

/usr/local/bin/install-cofi.sh

python -m pip install \
    papermill \
    nbformat \
    jupyterlab \
    notebook

python -m pip install --upgrade ipython ipykernel
python -m ipykernel install --name "python3" --display-name "Python 3"
