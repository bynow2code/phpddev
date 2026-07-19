FROM php:8.3.6-fpm

RUN apt-get update && apt-get install -y \
    htop \
    telnet  \
    procps  \
    iproute2  \
    && apt-get clean

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN install-php-extensions gd xdebug redis pdo_mysql zip

COPY conf.d/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

COPY --from=composer:2.10.1 /usr/bin/composer /usr/bin/composer