# PHP Docker 开发环境

基于 Docker Compose 的 PHP 多项目本地开发环境，提供 nginx + PHP-FPM + MySQL + Redis 的完整栈，支持多项目并行开发、Xdebug 断点调试，并与宿主机文件权限完全对齐。

## 服务一览

| 服务 | 镜像 | 宿主机端口 | 说明 |
|------|------|-----------|------|
| `nginx` | nginx:1.24.0 | `80` | Web 入口，按域名分发到各项目 |
| `core` | 自建 `php:8.3.6-fpm` | —（仅内部 9000） | 项目 core |
| `oms` | 同上 | — | 项目 oms |
| `wms` | 同上 | — | 项目 wms |
| `pms` | 同上 | — | 项目 pms |
| `mg` | 同上 | — | 项目 mg |
| `mysql` | mysql:8.0.45 | `3306` | 数据库 |
| `redis` | redis:7.0.15 | `6379` | 缓存 |
| `rabbitmq` | rabbitmq:4.1-management | `5672` / `15672` | 消息队列（AMQP + Web 管理台） |

站点域名：`core.test` / `oms.test` / `wms.test` / `pms.test` / `mg.test`

PHP 内置扩展：`gd` `xdebug` `redis` `pdo_mysql` `zip` `sockets`，另装 `composer`。

## 目录结构

```text
.
├── docker-compose.yml      # 服务编排
├── .env                    # 本地环境变量（已 gitignore）
├── .env.example            # 环境变量模板
├── bin/
│   └── init-env.sh         # 同步宿主机 UID/GID 到 .env
├── nginx/
│   └── conf.d/             # 每个站点一个 conf
│       ├── core.test_80.conf
│       └── ...
├── php/
│   ├── Dockerfile          # PHP-FPM 镜像
│   └── conf.d/
│       ├── xdebug.ini      # Xdebug 配置
│       └── timezone.ini    # 时区配置
├── mysql/conf/             # 预留（当前未挂载）
├── redis/conf/             # 预留（当前未挂载）
└── www/                    # 默认项目存放目录（内容不入库）
```

项目代码目录由 `.env` 中的 `PROJECT_ROOT` 决定，该目录会被挂载到容器内的 `/usr/share/nginx/html`。

## 快速开始

### 前置要求

- Docker Engine 20.10+（`extra_hosts: host-gateway` 需要此版本）
- Docker Compose v2

### 1. 初始化环境变量

```bash
cp .env.example .env
./bin/init-env.sh
```

`init-env.sh` 会把当前用户的 `id -u` / `id -g` 写入 `.env` 的 `WWWUSER` / `WWWGROUP`，避免容器与宿主机文件权限不一致。

### 2. 配置 hosts

在宿主机 `/etc/hosts` 中添加：

```text
127.0.0.1 core.test oms.test wms.test pms.test mg.test
```

### 3. 构建并启动

```bash
docker compose up -d --build
```

### 4. 访问

浏览器打开 <http://core.test>。

## 环境变量

| 变量 | 说明 | 示例 |
|------|------|------|
| `COMPOSE_PROJECT_NAME` | Compose 项目名，决定容器/网络前缀 | `phpddev` |
| `PROJECT_ROOT` | 宿主机项目根目录，挂载到容器 `/usr/share/nginx/html` | `../` 或 `./www` |
| `MYSQL_ROOT_PASSWORD` | MySQL root 密码 | `root123` |
| `WWWUSER` / `WWWGROUP` | 容器运行用户的 UID/GID，**须与宿主机当前用户一致** | `1000` |
| `TZ` | 容器时区 | `Asia/Shanghai` |
| `RABBITMQ_USER` / `RABBITMQ_PASSWORD` | RabbitMQ 登录凭据（**不可用 `guest`**） | `admin` / `admin123` |
| `RABBITMQ_VHOST` | RabbitMQ 虚拟主机 | `/` |

> `PROJECT_ROOT` 使用相对路径时，相对于 `docker-compose.yml` 所在目录。

## 常用命令

```bash
# 启动 / 停止
docker compose up -d                          # 启动
docker compose up -d --build                  # 重新构建并启动（改了 Dockerfile 或 ini 后必用）
docker compose down                           # 停止并删除容器

# 进入容器
docker compose exec mg bash                   # 进入 mg 容器
docker compose exec mg php artisan migrate    # 执行命令

# 日志
docker compose logs -f --tail=100 nginx       # 跟踪 nginx 日志
docker compose logs -f --tail=100 mg          # 跟踪 mg 容器日志

# 状态与校验
docker compose ps                             # 容器状态
docker compose config                         # 校验配置并输出解析结果

# 强制重建（配置解析结果等价时 Compose 不会重建容器）
docker compose up -d --force-recreate
```

## RabbitMQ

启动后即可使用：

| 项目 | 值 |
|------|-----|
| Web 管理界面 | <http://localhost:15672> |
| 宿主机 AMQP 地址 | `127.0.0.1:5672` |
| 容器内 AMQP 地址 | `rabbitmq:5672`（PHP 容器内直接用主机名） |
| 默认虚拟主机 | `/` |
| 账号 / 密码 | `.env` 中的 `RABBITMQ_USER` / `RABBITMQ_PASSWORD`（默认 `admin` / `admin123`） |

> **不要使用 `guest` 用户**：RabbitMQ 的 `guest` 默认只允许从 localhost 登录，PHP 容器属于远程连接会被拒绝（`ACCESS_REFUSED`）。因此这里默认创建 `admin` 用户。

常用运维命令：

```bash
docker compose exec rabbitmq rabbitmqctl list_queues        # 查看队列
docker compose exec rabbitmq rabbitmqctl list_connections   # 查看连接
docker compose exec rabbitmq rabbitmq-diagnostics -q ping   # 健康检查
docker compose logs -f --tail=100 rabbitmq                  # 跟踪日志
```

PHP 侧接入方式（二选一）：

- **纯 PHP 库**（无需扩展，开箱可用）：`composer require php-amqplib/php-amqplib`，本项目 mg 项目即使用此方案（`PhpAmqpLib\Connection\AMQPStreamConnection`）
- **amqp 扩展**（性能更好）：在 `php/Dockerfile` 的 `install-php-extensions` 参数中追加 `amqp`，然后 `docker compose up -d --build`

是否需要扩展取决于依赖的库：`php-amqplib/php-amqplib` 是纯 PHP 实现，无需扩展；只有依赖 `ext-amqp` 的包（或直接使用 `AMQPConnection`/`AMQPChannel` 类）才需要。判断方法是看 `vendor/<包名>/composer.json` 里 require 的是 `php-amqplib/...` 还是 `ext-amqp`。

> 项目 `.env` 中需注意：`RABBITMQ_HOST` 在容器内应填 `rabbitmq`（不能填 `127.0.0.1`），且不要使用 `guest` 用户。

## Xdebug 断点调试

容器内 Xdebug 3 已配置为**自动启动调试**，无需额外触发：

```ini
xdebug.mode=develop,debug
xdebug.client_host=host.docker.internal   # 回连宿主机
xdebug.start_with_request=yes             # 每个请求都尝试连接 IDE
xdebug.log_level=0                        # 关闭日志，避免 IDE 未监听时的警告噪音
xdebug.connect_timeout_ms=100
```

PhpStorm 配置要点：

1. **Settings → PHP → Debug**：确认 Debug port 为 `9003`，勾选 *Can accept external connections*
2. **Settings → PHP → Servers**：新增 Server，Name 必须与 `docker-compose.yml` 中 `PHP_IDE_CONFIG` 的 `serverName` 一致（如 `mg.test`），Host 填 `mg.test`，端口 `80`，勾选 *Use path mappings*，把宿主机项目目录映射到容器内 `/usr/share/nginx/html/mg`
3. 点击工具栏 **Start Listening for PHP Debug Connections**，然后在浏览器打断点访问

> 调试连不上时，可临时把 `xdebug.log_level` 改回 `7` 查看详细连接日志，定位后再改回 `0`。

## 新增项目

以新增项目 `foo` 为例：

1. **准备代码**：放到 `PROJECT_ROOT/foo`（Laravel 类项目入口为 `public/index.php`）

2. **新增 nginx 配置**：复制 `nginx/conf.d/core.test_80.conf` 为 `foo.test_80.conf`，修改：

   ```nginx
   server_name foo.test;
   root  /usr/share/nginx/html/foo/public;
   fastcgi_pass foo:9000;
   ```

3. **新增 compose 服务**：复制 `docker-compose.yml` 中的 `core` 服务块，改名为 `foo`，并修改：

   ```yaml
   foo:
     build:
       context: php
       dockerfile: Dockerfile
       args:
         UID: ${WWWUSER:-1000}
         GID: ${WWWGROUP:-1000}
     environment:
       TZ: ${TZ:-Asia/Shanghai}
       PHP_IDE_CONFIG: "serverName=foo.test"   # 改这里
     user: "${WWWUSER:-1000}:${WWWGROUP:-1000}"
     expose:
       - "9000"
     volumes:
       - ${PROJECT_ROOT}:/usr/share/nginx/html:cached
     extra_hosts:
       - "host.docker.internal:host-gateway"
     networks:
       - dev_net
     working_dir: /usr/share/nginx/html/foo       # 改这里
   ```

4. **加入 nginx 依赖与域名**：在 `nginx` 服务的 `depends_on` 和 `networks.dev_net.aliases` 中追加 `foo` / `foo.test`

5. **配置 hosts**：`127.0.0.1 foo.test`

6. **重建**：`docker compose up -d --build`

## 用户与文件权限

容器内进程以 `WWWUSER:WWWGROUP`（默认 `1000:1000`，即宿主机当前用户）运行，因此：

- 容器写入的日志、缓存、上传文件，在宿主机上属主就是你自己
- 宿主机修改的代码，容器内可直接读写
- **无需执行任何 `chown`**

镜像内会创建与 `WWWUSER` 同 UID 的用户 `dev`，并设为默认用户（`USER dev`），确保通过 `docker run` 或 IDE 直接启动时也不会退回 root。因此 **修改 `WWWUSER` 后必须 `docker compose up -d --build`**，否则镜像内用户 UID 与运行 UID 不一致，终端会显示 `I have no name!`。

php-fpm 的 `www.conf` 中 `user = www-data` 在本环境下不生效（master 非 root，无法降权），启动日志会出现：

```text
NOTICE: [pool www] 'user' directive is ignored when FPM is not running as root
```

这是预期行为，不影响功能。

## 时区

时区通过 `.env` 的 `TZ` 统一下发到所有服务。注意 PHP 与其他服务的机制不同：

| 使用方 | 时区来源 |
|--------|---------|
| nginx / MySQL / Redis / 系统命令 | `TZ` 环境变量（glibc `localtime`） |
| **PHP 的 `date()`** | **`php/conf.d/timezone.ini` 的 `date.timezone`**，不读取 `TZ` 环境变量 |

因此修改时区时，除改 `.env` 的 `TZ`，还需同步修改 `php/conf.d/timezone.ini` 并 `--build`。Laravel 项目侧还需保证 `config/app.php` 的 `timezone`（或 Laravel 11+ 的 `APP_TIMEZONE`）与之一致，否则框架会覆盖。

## 常见问题

| 现象 | 原因与处理 |
|------|-----------|
| 终端提示符显示 `I have no name!` | 镜像内 `dev` 用户 UID 与 `WWWUSER` 不一致，执行 `docker compose up -d --build` |
| Laravel 报 `storage` / `bootstrap/cache` 无法写入 | 容器 UID 与宿主机文件属主不一致，运行 `./bin/init-env.sh` 后 `--build` |
| 网站返回 **502** | ① PHP-FPM 未就绪，稍等重试；② PHP 容器重建后 IP 变化而 nginx 缓存了旧 IP，执行 `docker compose restart nginx` |
| nginx 容器启动失败 `host not found in upstream` | PHP 容器尚未创建，`depends_on` 已规避；若手动单独启动 nginx 需先启动 PHP 服务 |
| PHP 日志时间相差 8 小时 | `php/conf.d/timezone.ini` 未生效，检查是否遗漏 `--build` |
| Xdebug 断点不生效 | 检查 PhpStorm 的 Server Name 是否等于 `PHP_IDE_CONFIG` 的 `serverName`、端口 `9003`、是否已开启监听；排查时可把 `xdebug.log_level` 改回 `7` |
| 宿主机无法访问 `*.test` | 检查 `/etc/hosts` 是否配置了对应域名 |
| MySQL 连接失败 | 确认已执行 `docker compose up -d` 且 `mysql` 容器为 `Up`；连接地址在容器内用 `mysql`，从宿主机用 `127.0.0.1:3306` |
| RabbitMQ 报 `ACCESS_REFUSED` | 使用了 `guest` 用户（仅允许 localhost），改用 `.env` 中的 `admin` |
| RabbitMQ 管理界面打不开 | 首次启动需 20~30 秒初始化，用 `docker compose ps rabbitmq` 确认状态为 `healthy` |
| PHP 提示找不到 `AMQPConnection` 类 | 未安装 amqp 扩展，改用 `php-amqplib/php-amqplib`，或在 `php/Dockerfile` 增加 `amqp` 扩展后 `--build` |
