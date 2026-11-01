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

# 注意：ADD --chmod 需要 BuildKit，本机 docker 无 buildx 插件会回退到旧版 builder 直接报错
# 因此拆成「下载 + 手动 chmod」，两种 builder 都兼容
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/install-php-extensions
RUN chmod +x /usr/local/bin/install-php-extensions

RUN install-php-extensions gd xdebug redis pdo_mysql zip sockets

COPY conf.d/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini
COPY conf.d/timezone.ini /usr/local/etc/php/conf.d/timezone.ini

COPY --from=composer:2.10.1 /usr/bin/composer /usr/bin/composer

USER dev