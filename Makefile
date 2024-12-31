SHELL := /bin/bash

mode?=dev

# CELERY
nb_concurrent_worker_celery?=1

# DB
upgrade_db_extra?=false

module_directory?=".."

default: help

help:
	@echo "Available targets:"
	@echo "  install_nvm        - Install Node Version Manager (NVM)"
	@echo "  install_backend    - Install backend components"
	@echo "  install_db         - Create and set up the database"
	@echo "  install_contrib    - Install GeoNature modules"
	@echo "  install_extra      - Install extra GeoNature modules"
	@echo "  reset_install      - Reset installation"
	@echo "  back               - Start backend"
	@echo "  front              - Start frontend"
	@echo "  celery             - Start celery worker"


install_nvm:
	cd install/ && ./00_install_nvm.sh

install_backend:
	cd install/ && ./01_install_backend.sh

install_db:
	cd install/ && ./03_create_db.sh

install_contrib:
	source backend/venv/bin/activate && geonature install-gn-module contrib/occtax --build false --upgrade-db=${upgrade_db_extra}
	if [ "$add_sample_data" = true ]; then source backend/venv/bin/activate && geonature db upgrade occtax-samples@head;fi
	source backend/venv/bin/activate && geonature install-gn-module contrib/gn_module_occhab --build false --upgrade-db=${upgrade_db_extra}
	source backend/venv/bin/activate && geonature install-gn-module contrib/gn_module_validation  --build false --upgrade-db=${upgrade_db_extra}

install_frontend:
	cd install/ && ./05_install_frontend.sh

install_extra:
	source backend/venv/bin/activate && geonature install-gn-module "${module_directory}"/gn_module_monitoring --upgrade-db=${upgrade_db_extra}  --build=false
	source backend/venv/bin/activate && geonature install-gn-module "${module_directory}"/gn_module_export --upgrade-db=${upgrade_db_extra}  --build=false
	source backend/venv/bin/activate && geonature install-gn-module "${module_directory}"/gn_module_dashboard --upgrade-db=${upgrade_db_extra}  --build=false

reset_install: install_backend install_db install_modules

back:
	source backend/venv/bin/activate && geonature dev-back

front:
	cd frontend; nvm use; npm run start

celery:
	source backend/venv/bin/activate && celery -A geonature.celery_app:app worker -c $(nb_concurrent_worker_celery)

status:
	source backend/venv/bin/activate && geonature db status