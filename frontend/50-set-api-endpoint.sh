#!/bin/sh

if [ ! -z "${API_ENDPOINT}" ]; then
  echo "{\"API_ENDPOINT\": \"${API_ENDPOINT}\"}" >"${ASSETS_DIRECTORY:-/usr/share/nginx/html/assets}"/config.json
fi
