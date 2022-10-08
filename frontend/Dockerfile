FROM node:16-bullseye AS source

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
RUN cp -n src/custom/components/footer/footer.component.html.sample src/custom/components/footer/footer.component.html
RUN cp -n src/custom/components/footer/footer.component.ts.sample src/custom/components/footer/footer.component.ts
RUN cp -n src/custom/components/introduction/introduction.component.html.sample src/custom/components/introduction/introduction.component.html
RUN cp -n src/custom/components/introduction/introduction.component.ts.sample src/custom/components/introduction/introduction.component.ts
RUN cp -n src/custom/components/introduction/introduction.component.scss.sample src/custom/components/introduction/introduction.component.scss


FROM source AS source-full

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


FROM source AS build-light

WORKDIR /build/
RUN npm run build


FROM source-full AS build-full

WORKDIR /build/
RUN npm run build


FROM nginx:mainline-alpine AS prod

ENV NGINX_PORT 80
ENV NGINX_HOST localhost
ENV NGINX_LOCATION /

COPY ./frontend/nginx.conf /etc/nginx/templates/default.conf.template

EXPOSE 80


FROM prod AS prod-light

COPY --from=build-light /build/dist /usr/share/nginx/html


FROM prod AS prod-full

COPY --from=build-full /build/dist /usr/share/nginx/html
