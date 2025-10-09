#!/bin/bash
set -euo pipefail

# ============================================
# WiseFido Vault 初始化脚本（修正版）
# - 自动生成 TLS 证书（含权限修复）
# - 自动修复挂载卷权限
# - 自动检测 docker compose 文件
# - 自动等待 Vault 启动
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
# 2️⃣ 检查并生成 TLS 证书（防止 Vault 启动失败）
# ====================================================
CONFIG_DIR="${PROJECT_ROOT}/02_config"
CERT_FILE="${CONFIG_DIR}/vault_cert.pem"
KEY_FILE="${CONFIG_DIR}/vault_key.pem"

if [[ ! -f "$CERT_FILE" || ! -f "$KEY_FILE" ]]; then
  echo "⚠️  未检测到 Vault TLS 证书，自动生成临时自签证书..."
  mkdir -p "$CONFIG_DIR"
  openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$KEY_FILE" -out "$CERT_FILE" -days 365 \
    -subj "/C=US/ST=CA/L=SanFrancisco/O=WiseFido/OU=CA/CN=ca.wisefido.work"
  chmod 644 "$CERT_FILE"
  chmod 640 "$KEY_FILE"
  chown 100:100 "$CERT_FILE" "$KEY_FILE" || true
  echo "✅ 临时证书生成完成: ${CERT_FILE}"
else
  # 即使证书存在，也确保权限正确
  echo "🔹 检查 TLS 文件权限..."
  chmod 644 "$CERT_FILE" || true
  chmod 640 "$KEY_FILE" || true
  chown 100:100 "$CERT_FILE" "$KEY_FILE" || true
  echo "✅ TLS 权限检查完成。"
fi

# ====================================================
# 3️⃣ 自动修复挂载卷权限
# ====================================================
echo "🔹 检查并修复 Vault 挂载卷权限..."
sudo chown -R 100:100 "${PROJECT_ROOT}/03_deploy/vault" || true
sudo chmod -R 770 "${PROJECT_ROOT}/03_deploy/vault" || true
echo "✅ 权限检查与修复完成。"

# ====================================================
# 4️⃣ 启动 Vault 容器
# ====================================================
DOCKER_FILE="${PROJECT_ROOT}/03_deploy/01_docker-compose.yml"
if [[ ! -f "$DOCKER_FILE" ]]; then
  echo "❌ 错误：未找到 docker compose 文件：${DOCKER_FILE}"
  exit 1
fi

echo "🔹 启动 Vault 容器..."
docker compose -f "$DOCKER_FILE" up -d

# ====================================================
# 5️⃣ 等待 Vault 服务就绪
# ====================================================
echo "🔹 等待 Vault 服务启动中..."
for i in {1..30}; do
  if curl -sk https://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1; then
    echo "✅ Vault 已启动！"
    break
  fi
  echo "⏳ Vault 尚未就绪，等待中 (${i}s)..."
  sleep 2
  if [[ $i -eq 30 ]]; then
    echo "❌ Vault 启动超时，请检查容器日志："
    docker logs wisefido-vault | tail -n 20
    exit 1
  fi
done

# ====================================================
# 6️⃣ 初始化 Vault（仅在未初始化时执行）
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
# 7️⃣ 状态确认
# ====================================================
echo "🔹 检查 Vault 状态..."
docker exec -e VAULT_SKIP_VERIFY=true -i wisefido-vault vault status || true

echo "🎉 Vault 初始化流程全部完成！"
echo "👉 请务必妥善保管初始化密钥和 Root Token！"
echo "👉 你可以使用以下命令登录 Vault："
echo "   docker exec -e VAULT_SKIP_VERIFY=true -it wisefido-vault vault login <Root Token>"
echo "👉 访问 Vault UI: https://ca.wisefido.work:8200"
