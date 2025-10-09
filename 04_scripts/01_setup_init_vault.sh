#!/bin/bash
set -euo pipefail

# =========================================
# WiseFido Vault Deployment Script
# 自动路径识别 + 通用执行环境
# =========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "🔹 当前脚本路径: ${SCRIPT_DIR}"
echo "🔹 项目根路径:   ${PROJECT_ROOT}"

echo "🔹 创建 Vault 数据与日志目录..."
mkdir -p "${PROJECT_ROOT}/03_deploy/vault/data"
mkdir -p "${PROJECT_ROOT}/03_deploy/vault/logs"
chmod -R 755 "${PROJECT_ROOT}/03_deploy/vault"

echo "🔹 创建 CA 输出目录结构..."
mkdir -p "${PROJECT_ROOT}/05_opt/01_wisefido-ca"/{01_root,02_intermediate,03_issued/01_devices,04_crl}

echo "🔹 启动 Vault 容器..."
cd "${PROJECT_ROOT}/03_deploy"
docker compose up -d

echo "🔹 初始化 Vault..."
docker exec -i wisefido-vault vault operator init -key-shares=3 -key-threshold=2 \
  > "${PROJECT_ROOT}/05_opt/01_wisefido-ca/01_root/vault_init_keys.txt"

echo "✅ 初始化完成: ${PROJECT_ROOT}/05_opt/01_wisefido-ca/01_root/vault_init_keys.txt"
