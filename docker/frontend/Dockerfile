FROM nginx:1.16.1
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY plateform_name.conf plateform_name.conf
RUN export PLATEFORM_NAME="$(cat plateform_name.conf)"
RUN ln -s /data/build-front$(cat plateform_name.conf) /var/www
RUN echo /data/build-front$(cat plateform_name.conf)
RUN ls /var/www
EXPOSE 80

