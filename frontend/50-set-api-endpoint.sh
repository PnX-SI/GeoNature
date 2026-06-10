#!/bin/sh

if [ ! -z "${API_ENDPOINT}" ]; then
  echo "{\"API_ENDPOINT\": ${API_ENDPOINT}}" >/usr/share/nginx/html/assets/config.json
fi
