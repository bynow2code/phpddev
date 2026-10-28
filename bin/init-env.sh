#!/usr/bin/env bash
# 将宿主机当前用户的 UID/GID 同步到 .env 的 WWWUSER/WWWGROUP
# 用法: ./bin/init-env.sh
set -euo pipefail

cd "$(dirname "$0")/.."

[[ -f .env ]] || cp .env.example .env

HOST_UID=$(id -u)
HOST_GID=$(id -g)

if grep -q '^WWWUSER=' .env; then
    sed -i "s/^WWWUSER=.*/WWWUSER=${HOST_UID}/" .env
else
    printf '\nWWWUSER=%s\n' "${HOST_UID}" >> .env
fi

if grep -q '^WWWGROUP=' .env; then
    sed -i "s/^WWWGROUP=.*/WWWGROUP=${HOST_GID}/" .env
else
    printf 'WWWGROUP=%s\n' "${HOST_GID}" >> .env
fi

echo "已同步 WWWUSER=${HOST_UID} WWWGROUP=${HOST_GID} 到 .env"
