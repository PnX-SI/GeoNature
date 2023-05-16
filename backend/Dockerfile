# syntax=docker/dockerfile:1.2

FROM python:3.9-bullseye AS build

ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache \
    pip install --upgrade pip setuptools wheel


FROM build AS build-habref
WORKDIR /build/
COPY /backend/dependencies/Habref-api-module .
RUN python setup.py bdist_wheel


FROM build AS build-nomenclature
WORKDIR /build/
COPY /backend/dependencies/Nomenclature-api-module .
RUN python setup.py bdist_wheel


FROM build AS build-refgeo
WORKDIR /build/
COPY /backend/dependencies/RefGeo .
RUN python setup.py bdist_wheel


FROM build AS build-taxhub
WORKDIR /build/
COPY /backend/dependencies/TaxHub .
RUN python setup.py bdist_wheel


FROM build AS build-usershub
WORKDIR /build/
COPY /backend/dependencies/UsersHub .
RUN python setup.py bdist_wheel


FROM build AS build-usershub-module
WORKDIR /build/
COPY /backend/dependencies/UsersHub-authentification-module .
RUN python setup.py bdist_wheel


FROM build AS build-utils
WORKDIR /build/
COPY /backend/dependencies/Utils-Flask-SQLAlchemy .
RUN python setup.py bdist_wheel


FROM build AS build-utils-geo
WORKDIR /build/
COPY /backend/dependencies/Utils-Flask-SQLAlchemy-Geo .
RUN python setup.py bdist_wheel


FROM build AS build-geonature
WORKDIR /build/
COPY /backend ./backend
COPY /setup.py .
COPY /MANIFEST.in .
COPY /VERSION .
COPY /LICENSE .
COPY /README.md .
RUN python setup.py bdist_wheel


FROM build AS build-occtax
WORKDIR /build/
COPY /contrib/occtax/backend ./backend
COPY /contrib/occtax/setup.py .
COPY /contrib/occtax/requirements.in .
COPY /contrib/occtax/MANIFEST.in .
COPY /contrib/occtax/VERSION .
COPY /contrib/occtax/README.rst .
RUN python setup.py bdist_wheel


FROM build AS build-occhab
WORKDIR /build/
COPY /contrib/gn_module_occhab/backend ./backend
COPY /contrib/gn_module_occhab/setup.py .
COPY /contrib/gn_module_occhab/requirements.in .
COPY /contrib/gn_module_occhab/MANIFEST.in .
COPY /contrib/gn_module_occhab/VERSION .
COPY /contrib/gn_module_occhab/README.rst .
RUN python setup.py bdist_wheel


FROM build AS build-validation
WORKDIR /build/
COPY /contrib/gn_module_validation/backend ./backend
COPY /contrib/gn_module_validation/setup.py .
COPY /contrib/gn_module_validation/requirements.in .
COPY /contrib/gn_module_validation/MANIFEST.in .
COPY /contrib/gn_module_validation/VERSION .
COPY /contrib/gn_module_validation/README.rst .
RUN python setup.py bdist_wheel


FROM node:alpine AS node

WORKDIR /dist/
COPY /backend/static/package*.json .
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev


FROM python:3.9-bullseye AS wheels-light

ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache \
    pip install --upgrade pip setuptools wheel

WORKDIR /dist
ENV GEONATURE_STATIC_PATH=/dist/static/
COPY /backend/static/ ./static/
COPY --from=node /dist/node_modules/ ./static/node_modules/
ENV GEONATURE_CUSTOM_STATIC_PATH=/dist/custom/
RUN mkdir custom
ENV GEONATURE_MEDIA_PATH=/dist/media/
RUN mkdir -p media/attachments

WORKDIR /dist/geonature

COPY /backend/requirements-dev.txt .
RUN sed -i 's/^-e .*/# &/' requirements-dev.txt
RUN --mount=type=cache,target=/root/.cache \
    pip install -r requirements-dev.txt

COPY --from=build-habref /build/dist/*.whl .
COPY --from=build-nomenclature /build/dist/*.whl .
COPY --from=build-refgeo /build/dist/*.whl .
COPY --from=build-usershub /build/dist/*.whl .
COPY --from=build-usershub-module /build/dist/*.whl .
COPY --from=build-taxhub /build/dist/*.whl .
COPY --from=build-utils /build/dist/*.whl .
COPY --from=build-utils-geo /build/dist/*.whl .
COPY --from=build-geonature /build/dist/*.whl .

COPY --chmod=755 /install/03b_populate_db.sh ./populate_db.sh


ENV GEONATURE_CONFIG_FILE ""

EXPOSE 8000

CMD ["./populate_db.sh", "&&" \
    "gunicorn", "geonature:create_app()", \
    "--worker-tmp-dir=/dev/shm", \
    "--name=geonature", \
    "--workers=2", \
    "--threads=2", \
    "--access-logfile=-", \
    "--error-logfile=-", \
    "--bind=0.0.0.0:8000" \
]


FROM wheels-light AS wheels

COPY --from=build-occtax /build/dist/*.whl .
COPY --from=build-occhab /build/dist/*.whl .
COPY --from=build-validation /build/dist/*.whl .


FROM wheels-light AS prod-light

WORKDIR /dist/geonature
RUN --mount=type=cache,target=/root/.cache \
    pip install *.whl
RUN rm -f *.whl


FROM wheels AS prod

WORKDIR /dist/geonature
RUN --mount=type=cache,target=/root/.cache \
    pip install *.whl
RUN rm -f *.whl
