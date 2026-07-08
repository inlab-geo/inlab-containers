#!/bin/bash
set -euxo pipefail

BUILD_TMP=$(mktemp -d)
trap 'rm -rf "${BUILD_TMP}"' EXIT

# seislib's setup.py hardcodes -march=native for its Cython extensions, which
# bakes in build-machine-specific CPU instructions and can crash with
# "illegal instruction" when the built image runs on a different CPU. Strip
# it so the compiled extensions stay portable.
git clone --depth 1 https://github.com/fmagrini/seislib.git "${BUILD_TMP}/seislib"
find "${BUILD_TMP}/seislib" -name "setup.py" -exec sed -i 's/"-march=native", *//g' {} +
python -m pip install "${BUILD_TMP}/seislib"
