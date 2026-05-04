#!/bin/bash
set -euxo pipefail

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
