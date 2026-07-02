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

BUILD_TMP=$(mktemp -d)
trap 'rm -rf "${BUILD_TMP}"' EXIT

# seislib's setup.py hardcodes -march=native for its Cython extensions, which
# bakes in build-machine-specific CPU instructions and can crash with
# "illegal instruction" when the built image runs on a different CPU. Strip
# it so the compiled extensions stay portable.
git clone --depth 1 https://github.com/fmagrini/seislib.git "${BUILD_TMP}/seislib"
find "${BUILD_TMP}/seislib" -name "setup.py" -exec sed -i 's/"-march=native", *//g' {} +
python -m pip install "${BUILD_TMP}/seislib"
python -m pip install astroquery marimo

python -m pip install git+https://github.com/inlab-geo/pyfm2d
python -m pip install git+https://github.com/inlab-geo/pyrf96
python -m pip install git+https://github.com/inlab-geo/pyhk

git clone --depth 1 https://github.com/inlab-geo/pysurf96 "${BUILD_TMP}/pysurf96"
if [[ "$(uname -m)" == "aarch64" || "$(uname -m)" == "arm64" ]]; then
    find "${BUILD_TMP}/pysurf96" \
        -type f \( -name "*.py" -o -name "meson.build" -o -name "CMakeLists.txt" \) \
        -exec sed -i 's/-m64//g' {} +
fi
python -m pip install "${BUILD_TMP}/pysurf96"

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
