#! /bin/sh

echo "Creation du fichier de config"

#Global configuration
echo "SQLALCHEMY_DATABASE_URI = 'postgresql://$user_pg:$user_pg_pass@$db_host:$db_port/$db_name'" > config/geonature_config.toml
echo "URL_APPLICATION = 'http://${HOST_FRONT}'" >> config/geonature_config.toml
echo "API_ENDPOINT = 'http://${HOST}${GEONATURE_PATH}'" >> config/geonature_config.toml
echo "API_TAXHUB = 'http://${HOST}/taxhub/api'" >> config/geonature_config.toml
echo "APPLICATION_ROOT = '${GEONATURE_PATH}'" >> config/geonature_config.toml
echo "DEFAULT_LANGUAGE = '${default_language}'" >> config/geonature_config.toml
echo "LOCAL_SRID = '${srid_local}'" config/geonature_config.toml
echo "SECRET_KEY = '${SECRET_KEY}'" >> config/geonature_config.toml
echo "appName = '${APP_NAME}'" >> config/geonature_config.toml

#mail config
echo "[MAIL_CONFIG]" >> config/geonature_config.toml
echo "MAIL_SERVER = '${MAIL_SERVER}'" >> config/geonature_config.toml
echo "MAIL_PORT = ${MAIL_PORT}" >> config/geonature_config.toml
echo "MAIL_USE_TLS = '${MAIL_USE_TLS}'" >> config/geonature_config.toml
echo "MAIL_USE_SSL = '${MAIL_USE_SSL}'" >> config/geonature_config.toml
echo "MAIL_USERNAME = '${MAIL_USERNAME}'" >> config/geonature_config.toml
echo "MAIL_PASSWORD = '${MAIL_PASSWORD}'" >> config/geonature_config.toml
echo "MAIL_DEFAULT_SENDER = '${MAIL_DEFAULT_SENDER}'" >> config/geonature_config.toml

#BDD configuration
echo "[BDD]" >> config/geonature_config.toml
echo "ID_USER_SOCLE_1 = ${ID_USER_SOCLE_1}" >> config/geonature_config.toml

#MAP configuration
echo "[MAPCONFIG]" >> config/geonature_config.toml
echo "CENTER = ${CENTER}" >> config/geonature_config.toml
echo "ZOOM_LEVEL = ${ZOOM_LEVEL}" >> config/geonature_config.toml

#Alembic configuration
echo  "[ALEMBIC]" >> config/geonature_config.toml
echo "VERSION_LOCATIONS = '${VERSION_LOCATIONS}'" >> config/geonature_config.toml
