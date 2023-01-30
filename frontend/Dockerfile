FROM node:16-bullseye AS source-light

WORKDIR /build/

COPY ./frontend/package.json .
COPY ./frontend/package-lock.json .
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

COPY ./frontend/angular.json .
COPY ./frontend/tsconfig.json .
COPY ./frontend/external_modules external_modules
COPY ./frontend/src src
RUN cp -n src/assets/custom.sample.css src/assets/custom.css


FROM source-light AS source

WORKDIR /build/external_modules/occtax
COPY ./contrib/occtax/frontend/ .
#RUN --mount=type=cache,target=/root/.npm \
#    npm ci --omit=dev

WORKDIR /build/external_modules/occhab
COPY ./contrib/gn_module_occhab/frontend/ .
#RUN --mount=type=cache,target=/root/.npm \
#    npm ci --omit=dev

WORKDIR /build/external_modules/validation
COPY ./contrib/gn_module_validation/frontend/ .
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev


FROM source-light AS build-light

WORKDIR /build/
RUN npm run build


FROM source AS build

WORKDIR /build/
RUN npm run build


FROM nginx:mainline-alpine AS prod-base

ENV NGINX_PORT 80
ENV NGINX_HOST localhost
ENV NGINX_LOCATION /

COPY ./frontend/50-set-api-endpoint.sh /docker-entrypoint.d/

COPY ./frontend/nginx.conf /etc/nginx/templates/default.conf.template

EXPOSE 80


FROM prod-base AS prod-light

COPY --from=build-light /build/dist /usr/share/nginx/html


FROM prod-base AS prod

COPY --from=build /build/dist /usr/share/nginx/html
