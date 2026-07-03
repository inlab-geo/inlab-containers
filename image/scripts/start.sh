#!/bin/bash
set -e

(cd /home/jovyan/cofi-examples/cofi-paper && marimo edit --host 0.0.0.0 --port 2718) &

exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser \
  --notebook-dir=/home/jovyan/cofi-examples
