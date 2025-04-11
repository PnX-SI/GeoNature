SHELL := /bin/bash

#############################################################################
# Environment variables
#############################################################################

-include geonature.local.env

# defaultValues - if not defined in .env
PORT_USERSHUB ?= 5001
PORT_GN_FRONTEND ?= 4200
PORT_GN_BACKEND ?= 8000

PG_DB_NAME ?= geonature2db
PG_USER_NAME ?= gn_user
PG_USER_PASSWD ?= gn_passwd

GEONATURE_APP_NAME ?= 'DEV'

WITH_SAMPLE_DATA ?= false

MODULE_DASHBOARD_TAG ?= 1.5.0
MODULE_EXPORT_TAG ?= 1.7.2
MODULE_MONITORING_TAG ?= 1.0.0

MODULE_MONITORING_DIRECTORY ?= ../gn_module_monitoring
MODULE_EXPORT_DIRECTORY ?= ../gn_module_export
MODULE_DASHBOARD_DIRECTORY ?= ../gn_module_dashboard

# CELERY
NB_CONCURRENT_WORKER_CELERY?=1

# DB
UPGRADE_DB_EXTRA?=false

GEONATURE_DEFAULT_CONFIG_FILE = config/geonature_config.toml.sample
GEONATURE_LOCAL_CONFIG_FILE = config/geonature_config.toml

GEONATURE_DEFAULT_SETTING_FILE = config/settings.ini.sample
GEONATURE_LOCAL_SETTING_FILE = config/settings.ini
GEONATURE_APP_SECRET_KEY ?= 'yoursecretkey'

SUPERGRANT_NOM_ROLE ?= "Grp_admin"
SUPERGRANT_ISGROUP ?= true

default: help

help:
	@echo "Available targets:"
	@echo "  init_config_toml       - Initialize GeoNature configuration"
	@echo "  init_setting_init      - Initialize GeoNature settings"
	@echo "  activate_drop_db       - Activate the drop_db options in settings.ini"
	@echo "  deactivate_drop_db     - Deactivate the drop_db options in settings.ini"
	@echo "  update_settings        - Update settings and config files"
	@echo "  install_nvm            - Install Node Version Manager (NVM)"
	@echo "  install_backend        - Install backend components"
	@echo "  install_frontend       - Install frontend components"
	@echo "  install_db             - Create and set up the database"
	@echo "  install_contrib        - Install GeoNature modules"
	@echo "  install_extra          - Install extra GeoNature modules"
	@echo "  reset_install          - Reset installation"
	@echo "  back                   - Start backend"
	@echo "  front                  - Start frontend"
	@echo "  celery                 - Start celery worker"
	@echo "  db_status              - Show database status"
	@echo "  autoupgrade            - Upgrade the database"
	@echo "  test_frontend          - Run frontend tests"
	@echo "  test_backend           - Run backend tests"
	@echo "  lint_frontend          - Lint frontend code"
	@echo "  lint_backend           - Lint backend code"
	@echo "  compile_requirements   - Compile requirements"
	@echo "  supergrant             - Apply a supergrant to a user by its `nom_role`. By default, the supergrant is applied to the group `Grp_admin`. Check `SUPERGRANT_NOM_ROLE` and `SUPERGRANT_ISGROUP` to override the user and if it is a group or not."
	@echo "  benchmark              - Run benchmark"
	@echo "  docker_db              - Start populated database with docker (use it for dev and test only!)"

##############################
#### CONFIGURATION FILES ####
##############################

init_config_toml:
	cp -f $(GEONATURE_DEFAULT_CONFIG_FILE) $(GEONATURE_LOCAL_CONFIG_FILE)
	sed -i 's/SQLALCHEMY_DATABASE_URI = "postgresql:\/\/monuser:monpassachanger@localhost:5432\/mabase"/SQLALCHEMY_DATABASE_URI = "postgresql:\/\/$(PG_USER_NAME):$(PG_USER_PASSWD)@localhost:5432\/$(PG_DB_NAME)"/g' $(GEONATURE_LOCAL_CONFIG_FILE)
	sed -i "s/SECRET_KEY = 'super secret key'/SECRET_KEY = $(GEONATURE_APP_SECRET_KEY)/g" $(GEONATURE_LOCAL_CONFIG_FILE)
	sed -i "s/SECRET_KEY = $(GEONATURE_APP_SECRET_KEY)/SECRET_KEY = $(GEONATURE_APP_SECRET_KEY)\n\n\# Nom de l'application dans la page d'accueil\nappName = $(GEONATURE_APP_NAME)/g" $(GEONATURE_LOCAL_CONFIG_FILE)
	sed -i "s/URL_APPLICATION = 'http:\/\/url.com\/geonature'/URL_APPLICATION = 'http:\/\/localhost:$(PORT_GN_FRONTEND)'/g" $(GEONATURE_LOCAL_CONFIG_FILE)
	sed -i "s/API_ENDPOINT = 'http:\/\/url.com\/geonature\/api'/API_ENDPOINT = 'http:\/\/localhost:$(PORT_GN_BACKEND)'/g" $(GEONATURE_LOCAL_CONFIG_FILE)
	sed -i "s/API_TAXHUB = 'http:\/\/url.com\/taxhub\/api'/API_TAXHUB = 'http:\/\/localhost:$(PORT_TAXUB)\/api'/g" $(GEONATURE_LOCAL_CONFIG_FILE)

init_settings_ini:
	cp -f $(GEONATURE_DEFAULT_SETTING_FILE) $(GEONATURE_LOCAL_SETTING_FILE)
	sed -i 's/MODE=prod/MODE=dev/g' $(GEONATURE_LOCAL_SETTING_FILE)
	sed -i 's/my_url=http:\/\/url.com\//my_url=http:\/\/localhost:$(PORT_GN_FRONTEND)\//g' $(GEONATURE_LOCAL_SETTING_FILE)
	sed -i 's/db_name=geonature2db/db_name=$(PG_DB_NAME)/g' $(GEONATURE_LOCAL_SETTING_FILE)
	sed -i 's/user_pg=geonatadmin/user_pg=$(PG_USER_NAME)/g' $(GEONATURE_LOCAL_SETTING_FILE)
	sed -i 's/user_pg_pass=monpassachanger/user_pg_pass=$(PG_USER_PASSWD)/g' $(GEONATURE_LOCAL_SETTING_FILE)
	sed -i 's/install_default_dem=true/install_default_dem=false/g' $(GEONATURE_LOCAL_SETTING_FILE)
	sed -i 's/add_sample_data=true/add_sample_data=$(WITH_SAMPLE_DATA)/g' $(GEONATURE_LOCAL_SETTING_FILE)
	sed -i 's/install_module_validation=false/install_module_validation=true/g' $(GEONATURE_LOCAL_SETTING_FILE)
	sed -i 's/install_module_occhab=false/install_module_occhab=true/g' $(GEONATURE_LOCAL_SETTING_FILE)

deactivate_drop_db:
	sed -i 's/drop_apps_db=true/drop_apps_db=false/g' $(GEONATURE_LOCAL_SETTING_FILE)

activate_drop_db:
	sed -i 's/drop_apps_db=false/drop_apps_db=true/g' $(GEONATURE_LOCAL_SETTING_FILE)


update_settings: geonature_init_settings geonature_init_config

##############################
##### INSTALLATION ###########
##############################

install_nvm:
	cd install/ && ./00_install_nvm.sh

install_backend:
	cd install/ && ./01_install_backend.sh

install_frontend:
	cd install/ && ./05_install_frontend.sh

install_db:
	cd install/ && ./03_create_db.sh

install_contrib:
	source backend/venv/bin/activate && geonature install-gn-module contrib/occtax --build false --upgrade-db=${UPGRADE_DB_EXTRA}
	if [ "${WITH_SAMPLE_DATA}" = true ]; then source backend/venv/bin/activate && geonature db upgrade occtax-samples@head;fi
	source backend/venv/bin/activate && geonature install-gn-module contrib/gn_module_occhab --build false --upgrade-db=${UPGRADE_DB_EXTRA}
	source backend/venv/bin/activate && geonature install-gn-module contrib/gn_module_validation  --build false --upgrade-db=${UPGRADE_DB_EXTRA}

install_extra:
	cd ${MODULE_MONITORING_DIRECTORY} && git checkout ${MODULE_MONITORING_TAG}
	cd ${MODULE_EXPORT_DIRECTORY} && git checkout ${MODULE_EXPORT_TAG}
	cd ${MODULE_DASHBOARD_DIRECTORY} && git checkout ${MODULE_DASHBOARD_TAG}
	source backend/venv/bin/activate && geonature install-gn-module "${MODULE_MONITORING_DIRECTORY}" --upgrade-db=${UPGRADE_DB_EXTRA}  --build=false
	source backend/venv/bin/activate && geonature install-gn-module "${MODULE_EXPORT_DIRECTORY}" --upgrade-db=${UPGRADE_DB_EXTRA}  --build=false
	source backend/venv/bin/activate && geonature install-gn-module "${MODULE_DASHBOARD_DIRECTORY}" --upgrade-db=${UPGRADE_DB_EXTRA}  --build=false

install_modules: install_contrib install_extra

reset_install: install_backend install_db install_modules

##############################
##### DEPLOYMENT ###########
##############################

back:
	source backend/venv/bin/activate && geonature dev-back --port ${PORT_GN_BACKEND}

front:
	. ${NVM_DIR}/nvm.sh; cd frontend; nvm use; npm run start -- --port ${PORT_GN_FRONTEND}

celery:
	source backend/venv/bin/activate && celery -A geonature.celery_app:app worker -c ${NB_CONCURRENT_WORKER_CELERY}

db_status:
	source backend/venv/bin/activate && geonature db status

docker_db:
	docker run -d \
    --rm -p 5432:5432 \
    --name geonature-db \
    ghcr.io/pnx-si/geonature-db:latest

autoupgrade:
	source backend/venv/bin/activate && geonature db autoupgrade

compile_requirements:
	source backend/venv/bin/activate && cd backend && piptools compile requirements.in
	source backend/venv/bin/activate && cd backend && piptools compile requirements-dev.in

test_frontend:
	. ${NVM_DIR}/nvm.sh; cd frontend; nvm use && npm run cypress:run

test_backend:
	source backend/venv/bin/activate && pytest

benchmark:
	source backend/venv/bin/activate && pytest --benchmark-only

lint_frontend:
	. ${NVM_DIR}/nvm.sh; cd frontend; nvm use; npm run format

lint_backend:
	source backend/venv/bin/activate && black .

supergrant:
	if [ "${SUPERGRANT_ISGROUP}" = true ]; then source backend/venv/bin/activate && geonature permissions supergrant --group --nom ${SUPERGRANT_NOM_ROLE} --yes; fi
	if [ "${SUPERGRANT_ISGROUP}" = false ]; then source backend/venv/bin/activate && geonature permissions supergrant --nom ${SUPERGRANT_NOM_ROLE} --yes; fi

# Add other targets in a Makefile.local file if you wish to extend the make file
-include Makefile.local