HOST=0.0.0.0
PORT=8000
VENV=venv
WORKERS=4
APP_NAME=geonature2

develop:
	@/bin/bash -c "source $(VENV)/bin/activate&&python server.py runserver -d -r -h $(HOST) -p $(PORT)"


prod:
	@/bin/bash -c "source $(VENV)/bin/activate&&gunicorn --daemon --pid='$(APP_NAME).pid' --error-log /tmp/errors.log -w $(WORKERS) -b '$(HOST):$(PORT)' -n '$(APP_NAME)' server:app"&&echo "Serveur activé sur '$(HOST):$(PORT)'"

prod-stop:
	@kill `cat $(APP_NAME).pid`&&echo "Terminé."


shell:
	@/bin/bash -c "source $(VENV)/bin/activate&&python server.py shell"
