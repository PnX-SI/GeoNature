#!/bin/bash

FLASKDIR=$(readlink -e "${0%/*}")
APP_DIR="$(dirname "$FLASKDIR")"

echo "Starting $app_name"
echo "$FLASKDIR"
echo "$(dirname $0)/config/settings.ini"
echo $APP_DIR
. $APP_DIR/config/settings.ini

# Activation de la configuration des proxy si necessaire
[[ -z "$proxy_http" ]] || export HTTP_PROXY="'$proxy_http'"
[[ -z "$proxy_https" ]] || export HTTPS_PROXY="'$proxy_https'"

# activate the virtualenv
source $FLASKDIR/$venv_dir/bin/activate

cd $FLASKDIR

# Start your gunicorn
exec gunicorn  wsgi:app --error-log $APP_DIR/var/log/gn_errors.log --timeout $gun_timeout --pid="${app_name}.pid" -w "${gun_num_workers}"  -b "${gun_host}:${gun_port}"  -n "${app_name}"
