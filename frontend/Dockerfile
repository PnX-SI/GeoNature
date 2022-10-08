FROM node:16-bullseye AS source

WORKDIR /dist/geonature/frontend

COPY ./package.json .
COPY ./package-lock.json .
RUN npm ci --omit=dev

COPY . .
RUN cp -n src/assets/custom.sample.css src/assets/custom.css
RUN cp -n src/custom/components/footer/footer.component.html.sample src/custom/components/footer/footer.component.html
RUN cp -n src/custom/components/footer/footer.component.ts.sample src/custom/components/footer/footer.component.ts
RUN cp -n src/custom/components/introduction/introduction.component.html.sample src/custom/components/introduction/introduction.component.html
RUN cp -n src/custom/components/introduction/introduction.component.ts.sample src/custom/components/introduction/introduction.component.ts
RUN cp -n src/custom/components/introduction/introduction.component.scss.sample src/custom/components/introduction/introduction.component.scss


FROM source AS build

RUN npm run build


FROM nginx:mainline-alpine AS nginx

COPY --from=build /dist/geonature/frontend/dist /usr/share/nginx/html

EXPOSE 80
