#!/bin/bash

FLASKDIR=$(readlink -e "${0%/*}")
APP_DIR="$(dirname "$FLASKDIR")"

echo "Starting $app_name"
echo "$FLASKDIR"
echo "$(dirname $0)/config/settings.ini"
echo $APP_DIR
. $APP_DIR/config/settings.ini

# activate the virtualenv
source $FLASKDIR/$venv_dir/bin/activate

cd $FLASKDIR

# Start your gunicorn
exec gunicorn  wsgi:app --pid="${app_name}.pid" -w "${gun_num_workers}"  -b "${gun_host}:${gun_port}"  -n "${app_name}"
