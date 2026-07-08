#!/bin/bash
set -euxo pipefail

python -m pip install \
    numba \
    llvmlite \
    "seaborn>=0.13"

python -m pip install git+https://github.com/obspy/obspy.git

python -m pip install astroquery

python -m pip install git+https://github.com/inlab-geo/pyrf96
python -m pip install git+https://github.com/inlab-geo/pyhk

BUILD_TMP=$(mktemp -d)
trap 'rm -rf "${BUILD_TMP}"' EXIT

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

python -m pip install \
    papermill \
    jupyterlab \
    notebook

python -m pip install --upgrade ipython ipykernel
python -m ipykernel install --name "python3" --display-name "Python 3"
