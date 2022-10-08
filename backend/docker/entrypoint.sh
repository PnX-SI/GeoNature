#!/bin/bash

set -e


# Activate venv
. /dist/venv/bin/activate

# exec
exec "$@"
