FROM python:3.7-bullseye
RUN apt-get update

RUN mkdir /GeoNature
WORKDIR /GeoNature

# Install apt packages
COPY apt-packages.txt /GeoNature
RUN xargs apt-get install -y <apt-packages.txt
RUN wget -qO- https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get update
RUN apt-get install -y nodejs
# Install python packages
RUN mkdir /GeoNature/backend
RUN mkdir /GeoNature/frontend
COPY backend/requirements.txt /GeoNature/backend
COPY backend/requirements-common.txt /GeoNature/backend
RUN pip3 install --upgrade pip
RUN pip3 install -r backend/requirements.txt

RUN echo "Europe/P" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    sed -i -e 's/# fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# nb_NO.UTF-8 UTF-8/nb_NO.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="nb_NO.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=nb_NO.UTF-8 \
RUN export LC_ALL=fr_FR.UTF-8
RUN export LANGUAGE=fr_FR.UTF-8
RUN export LANG=fr_FR.UTF-8

#Install frontend dependences

COPY . /GeoNature/
COPY ./install/install_all/install_all.ini /GeoNature
COPY ./install/install_all/install_all.sh /GeoNature

RUN pip3 install -e /GeoNature/contrib/occtax
RUN pip3 install -e /GeoNature/contrib/gn_module_validation
RUN pip3 install -e /GeoNature/contrib/gn_module_occhab




ENTRYPOINT ["sh", "entrypoint.sh"]
EXPOSE 80
