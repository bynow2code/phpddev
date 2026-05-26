# 开发环境选择不用 Alpine 版本，用 Debian 完整版
FROM php:8.3.6-fpm

# 安装常用扩展
RUN docker-php-ext-install pdo_mysql
RUN pecl install redis xdebug && docker-php-ext-enable redis xdebug

# 配置 Xdebug
RUN echo "xdebug.mode=develop,debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# 安装 Composer（可选，也可以在单独的 composer 容器中做）
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 工作目录
WORKDIR /usr/share/nginx/html

# 前台运行 php-fpm
CMD ["php-fpm"]