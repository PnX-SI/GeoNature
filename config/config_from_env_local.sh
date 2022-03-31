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


#Alembic configuration
echo  "[ALEMBIC]" >> config/geonature_config.toml
echo "VERSION_LOCATIONS = '${VERSION_LOCATIONS}'" >> config/geonature_config.toml
