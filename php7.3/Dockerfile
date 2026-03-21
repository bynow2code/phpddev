# 开发环境选择不用 Alpine 版本，用 Debian 完整版
FROM php:7.3.33-fpm

# 配置 Debian 源并安装依赖
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     # 新增开发常用工具
#     vim \
#     git \
#     curl \
#     unzip \
#     # 清理缓存减少镜像体积
#     && rm -rf /var/lib/apt/lists/*  

# 安装 PHP 扩展安装工具
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions redis pdo_mysql xdebug

# 配置 Xdebug 调试
RUN echo "xdebug.mode=debug,develop" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.discover_client_host=0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.max_nesting_level=500" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
# 开发:
RUN cp $PHP_INI_DIR/php.ini-development $PHP_INI_DIR/php.ini

COPY --from=composer:2.8.10 /usr/bin/composer /usr/bin/composer
