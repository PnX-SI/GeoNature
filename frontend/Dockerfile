ARG NODE_IMAGE="node:20-bullseye"
ARG NGINX_IMAGE="nginx:mainline-alpine"


FROM ${NODE_IMAGE} AS occhab-node-modules

WORKDIR /dist/gn_module_occhab

COPY ./contrib/gn_module_occhab/frontend/package.json .
COPY ./contrib/gn_module_occhab/frontend/package-lock.json .

RUN --mount=type=cache,target=/root/.npm \
  npm ci --omit=peer

FROM ${NODE_IMAGE} AS source-light

WORKDIR /build/

COPY ./frontend/package.json .
COPY ./frontend/package-lock.json .
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

COPY ./frontend/angular.json .
COPY ./frontend/tsconfig.json .
COPY ./frontend/external_modules external_modules
COPY ./frontend/src src


FROM source-light AS source

WORKDIR /build/external_modules/occtax
COPY ./contrib/occtax/frontend/ .

WORKDIR /build/external_modules/occhab
COPY ./contrib/gn_module_occhab/frontend/ .
COPY --from=occhab-node-modules /dist/gn_module_occhab/node_modules .

WORKDIR /build/external_modules/validation
COPY ./contrib/gn_module_validation/frontend/ .


FROM source-light AS build-light

WORKDIR /build/
RUN npm run build


FROM source AS build

WORKDIR /build/
RUN npm run build


FROM ${NGINX_IMAGE} AS prod-base

ENV NGINX_PORT=80
ENV NGINX_HOST=localhost
ENV NGINX_LOCATION=/

ENV ASSETS_DIRECTORY=/usr/share/nginx/html/assets
COPY ./frontend/50-set-api-endpoint.sh /docker-entrypoint.d/

COPY ./frontend/nginx.conf /etc/nginx/templates/default.conf.template

EXPOSE 80


FROM prod-base AS prod-light

COPY --from=build-light /build/dist /usr/share/nginx/html


FROM prod-base AS prod

COPY --from=build /build/dist /usr/share/nginx/html

FROM ${NODE_IMAGE} AS dev

WORKDIR /dist/geonature

COPY ./frontend/package.json .
COPY ./frontend/package-lock.json .

RUN --mount=type=cache,target=/root/.npm \
  npm ci

COPY ./frontend/tsconfig.json .
COPY ./frontend/angular.json .

COPY --from=occhab-node-modules /dist/gn_module_occhab /dist/gn_module_occhab

RUN mkdir external_modules
RUN ln -s /dist/occtax external_modules/occtax
RUN ln -s /dist/gn_module_occhab external_modules/occhab
RUN ln -s /dist/gn_module_validation external_modules/validation

ENV ASSETS_DIRECTORY=/dist/geonature/src/assets
RUN mkdir /docker-entrypoint.d/
COPY ./frontend/50-set-api-endpoint.sh /docker-entrypoint.d/
COPY ./frontend/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD [ "npm", "run", "start", "--", "--host", "0.0.0.0" ]

EXPOSE 4200
