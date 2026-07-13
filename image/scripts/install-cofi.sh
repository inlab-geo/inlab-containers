#!/bin/bash
set -euxo pipefail

# cofi depends on torch>=2.0.0, and PyPI's default Linux torch wheel drags in
# the full NVIDIA CUDA toolkit (~4.5GB of cuBLAS/cuDNN/triton/etc.) as
# transitive deps. None of that is usable in a plain container without a
# passed-through GPU, so pin the official CPU-only build first; pip then
# treats torch>=2.0.0 as already satisfied when it resolves cofi below.
python -m pip install "torch<2.13" --index-url https://download.pytorch.org/whl/cpu

python -m pip install \
    emcee \
    bayesbay \
    findiff \
    "mealpy>=3.0.0,<3.0.3" \
    neighpy \
    opfunu \
    shapely

if [[ "${COFI_INSTALL_SOURCE:-pypi}" == "git" ]]; then
    python -m pip install "git+https://github.com/inlab-geo/cofi.git@${COFI_REF:-main}"
elif [[ "${COFI_VERSION:-latest}" == "latest" ]]; then
    python -m pip install cofi
else
    python -m pip install "cofi==${COFI_VERSION}"
fi
