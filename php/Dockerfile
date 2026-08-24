FROM php:8.3.6-fpm

ARG UID=1000
ARG GID=1000
RUN groupadd -g ${GID} dev \
    && useradd -u ${UID} -g ${GID} -m -s /bin/bash dev

RUN apt-get update && apt-get install -y \
    htop \
    telnet \
    procps \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN install-php-extensions gd xdebug redis pdo_mysql zip sockets

COPY conf.d/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

COPY --from=composer:2.10.1 /usr/bin/composer /usr/bin/composer

USER dev