#!/bin/bash
set -euo pipefail
PROJECT_ROOT="/opt/00_WiseFido_CA_Project"

echo "🔹 准备目录..."
mkdir -p "${PROJECT_ROOT}/05_opt/01_wisefido-ca/01_root"
mkdir -p "${PROJECT_ROOT}/05_opt/01_wisefido-ca/02_intermediate"
mkdir -p "${PROJECT_ROOT}/05_opt/01_wisefido-ca/03_issued/01_devices"
mkdir -p "${PROJECT_ROOT}/05_opt/01_wisefido-ca/04_crl"

# 若无 TLS 证书，临时生成自签（仅为启动 Vault 用）
if [[ ! -f "${PROJECT_ROOT}/02_config/vault_cert.pem" || ! -f "${PROJECT_ROOT}/02_config/vault_key.pem" ]]; then
  echo "🔹 生成临时自签 TLS 证书（启动用，后续可替换为正式证书）..."
  openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
    -subj "/CN=ca.wisefido.work/O=WiseFido Inc./C=US" \
    -keyout "${PROJECT_ROOT}/02_config/vault_key.pem" \
    -out "${PROJECT_ROOT}/02_config/vault_cert.pem"
fi

echo "🔹 启动 Vault 容器（Docker Compose）..."
cd "${PROJECT_ROOT}/03_deploy"
docker compose up -d

echo "🔹 初始化 Vault..."
docker exec -i wisefido-vault vault operator init -key-shares=3 -key-threshold=2 \
  > "${PROJECT_ROOT}/05_opt/01_wisefido-ca/01_root/vault_init_keys.txt"

echo "✅ 完成：${PROJECT_ROOT}/05_opt/01_wisefido-ca/01_root/vault_init_keys.txt"
echo "⚠️ 请立即离线备份该文件，并限制访问权限。"
