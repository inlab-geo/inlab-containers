#!/bin/bash
set -euxo pipefail

python -m pip install pygimli
python -c 'import pygimli as pg; print(pg.__version__)'
