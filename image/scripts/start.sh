#!/bin/bash
set -e

MARIMO_TOKEN=$(python -c 'import secrets; print(secrets.token_hex(24))')
JUPYTER_TOKEN=$(python -c 'import secrets; print(secrets.token_hex(24))')

cat <<EOF

================================================================
  Marimo notebook:  http://127.0.0.1:2718?access_token=${MARIMO_TOKEN}
  Jupyter Lab:       http://127.0.0.1:8888/lab?token=${JUPYTER_TOKEN}
================================================================

EOF

(cd /home/jovyan/cofi-examples/cofi-paper && marimo edit --host 0.0.0.0 --port 2718 --token --token-password="${MARIMO_TOKEN}") &

exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser \
  --notebook-dir=/home/jovyan/cofi-examples \
  --IdentityProvider.token="${JUPYTER_TOKEN}" \
  --ServerApp.custom_display_url="http://127.0.0.1:8888/lab?token=${JUPYTER_TOKEN}"
