#!/bin/bash
set -euxo pipefail

if [[ "${PYGIMLI_VERSION:-latest}" == "latest" ]]; then
    python -m pip install pygimli pgcore
else
    python -m pip install "pygimli==${PYGIMLI_VERSION}" "pgcore==${PYGIMLI_VERSION}"
fi

python -c 'import pygimli as pg; print(pg.__version__)'
