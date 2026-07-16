#!/bin/bash
set -e

(cd /home/jovyan/cofi-examples/cofi-paper && marimo edit --host 0.0.0.0 --port 2718) &

JUPYTER_TOKEN=$(python -c 'import secrets; print(secrets.token_hex(24))')

exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser \
  --notebook-dir=/home/jovyan/cofi-examples \
  --IdentityProvider.token="${JUPYTER_TOKEN}" \
  --ServerApp.custom_display_url="http://127.0.0.1:8888/lab?token=${JUPYTER_TOKEN}"
