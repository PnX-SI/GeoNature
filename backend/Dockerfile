# syntax=docker/dockerfile:1.2

FROM python:3.9-bullseye AS source

WORKDIR /dist/geonature
COPY /data ./data
COPY /backend ./backend
COPY /setup.py .
COPY /MANIFEST.in .
COPY /VERSION .
COPY /LICENSE .
COPY /README.md .


FROM source AS dev

WORKDIR /dist/geonature/backend

RUN python3 -m venv /dist/venv
RUN --mount=type=cache,target=/root/.cache \
    /dist/venv/bin/pip install --upgrade pip setuptools wheel
RUN --mount=type=cache,target=/root/.cache \
    /dist/venv/bin/pip install -e ..[tests] -r requirements-dev.txt

COPY /backend/docker/update.sh /usr/local/bin/
COPY /backend/docker/entrypoint.dev.sh /usr/local/bin/entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["entrypoint.sh"]

CMD ["geonature", "dev_back"]


FROM node:alpine AS node

WORKDIR /dist/
COPY /backend/static/package*.json .
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev


FROM source AS build

ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache \
    pip install --upgrade pip setuptools wheel build
RUN python -m build

FROM python:3.9-bullseye AS prod

WORKDIR /dist/geonature
COPY /backend/requirements.txt .
COPY --from=build /dist/geonature/dist/geonature-*.whl .
ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache \
    pip install --upgrade pip setuptools wheel
RUN --mount=type=cache,target=/root/.cache \
    pip install -r requirements.txt geonature-*.whl

WORKDIR /dist
COPY /backend/static/ ./static/
COPY --from=node /dist/node_modules/ ./static/node_modules/
COPY /backend/docker/update.sh /usr/local/bin/
COPY /backend/docker/entrypoint.prod.sh /usr/local/bin/entrypoint.sh

ENV GEONATURE_STATIC_FOLDER=/dist/static/

EXPOSE 8000

CMD ["gunicorn", "geonature:create_app()", "--bind=0.0.0.0:8000"]
