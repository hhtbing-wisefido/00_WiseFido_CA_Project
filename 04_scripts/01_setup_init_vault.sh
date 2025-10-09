#!/bin/bash
set -euo pipefail

# ============================================
# WiseFido Vault 初始化脚本（最终稳定版）
# 版本：v2.1
# 功能：
#   1. 自动识别项目路径
#   2. 创建目录结构
#   3. 启动 Vault 容器
#   4. 等待服务就绪
#   5. 跳过 TLS 验证执行初始化
# ============================================

# 自动识别路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
echo "🔹 当前脚本路径: ${SCRIPT_DIR}"
echo "🔹 项目根路径:   ${PROJECT_ROOT}"

# ====================================================
# 1️⃣ 创建部署所需目录结构
# ====================================================
echo "🔹 创建 Vault 数据与日志目录..."
mkdir -p "${PROJECT_ROOT}/03_deploy/vault/data"
mkdir -p "${PROJECT_ROOT}/03_deploy/vault/logs"
chmod -R 755 "${PROJECT_ROOT}/03_deploy/vault"

echo "🔹 创建 CA 输出目录结构..."
mkdir -p "${PROJECT_ROOT}/05_opt/01_wisefido-ca"/{01_root,02_intermediate,03_issued/01_devices,04_crl}
chmod -R 755 "${PROJECT_ROOT}/05_opt/01_wisefido-ca"

# ====================================================
# 2️⃣ 启动 Vault 容器
# ====================================================
echo "🔹 启动 Vault 容器..."
docker compose -f "${PROJECT_ROOT}/03_deploy/01_docker-compose.yml" up -d

# ====================================================
# 3️⃣ 等待 Vault 服务就绪
# ====================================================
echo "🔹 等待 Vault 服务启动中..."
for i in {1..30}; do
  if docker exec -e VAULT_SKIP_VERIFY=true wisefido-vault vault status >/dev/null 2>&1; then
    echo "✅ Vault 已启动！"
    break
  fi
  echo "⏳ Vault 尚未就绪，等待中 (${i}s)..."
  sleep 2
done

# ====================================================
# 4️⃣ 初始化 Vault（仅在未初始化时执行）
# ====================================================
STATUS=$(docker exec -e VAULT_SKIP_VERIFY=true wisefido-vault vault status 2>/dev/null || true)

if echo "$STATUS" | grep -q "Initialized.*true"; then
  echo "⚠️ Vault 已初始化，跳过 init 步骤。"
else
  echo "🔹 初始化 Vault..."
  docker exec -e VAULT_SKIP_VERIFY=true -i wisefido-vault vault operator init -key-shares=3 -key-threshold=2 \
    > "${PROJECT_ROOT}/05_opt/01_wisefido-ca/01_root/vault_init_keys.txt"
  echo "✅ Vault 初始化完成。"
  echo "🔐 初始化密钥保存路径：${PROJECT_ROOT}/05_opt/01_wisefido-ca/01_root/vault_init_keys.txt"
fi

# ====================================================
# 5️⃣ 状态确认
# ====================================================
echo "🔹 检查 Vault 状态..."
docker exec -e VAULT_SKIP_VERIFY=true -i wisefido-vault vault status || true

echo "✅ 初始化流程全部完成！"
