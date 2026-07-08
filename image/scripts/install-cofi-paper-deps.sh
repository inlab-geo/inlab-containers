#!/bin/bash
set -euxo pipefail

/usr/local/bin/install-seislib.sh

python -m pip install -r /home/jovyan/cofi-examples/cofi-paper/requirements.txt
