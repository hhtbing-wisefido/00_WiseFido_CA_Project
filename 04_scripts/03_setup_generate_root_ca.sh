#!/bin/bash
set -euo pipefail
PROJECT_ROOT="/opt/00_WiseFido_CA_Project"
ROOT_DIR="${PROJECT_ROOT}/05_opt/01_wisefido-ca/01_root"

read -p "请输入 Vault Root Token: " token
export VAULT_ADDR="http://127.0.0.1:8201"
export VAULT_TOKEN="$token"
export VAULT_SKIP_VERIFY=true

# ==============================
# 检查 Vault 是否可访问
# ==============================
echo "🔹 检查 Vault 内部 API 是否就绪..."
for i in {1..10}; do
  if curl -s http://127.0.0.1:8201/v1/sys/health >/dev/null 2>&1; then
    echo "✅ Vault 内部接口可用。"
    break
  fi
  echo "⏳ Vault 尚未响应 (${i}s)..."
  sleep 2
  if [[ $i -eq 10 ]]; then
    echo "❌ Vault 无法连接，请检查容器状态。"
    exit 1
  fi
done

# ==============================
# 启用 Root PKI 引擎
# ==============================
docker exec \
  -e VAULT_ADDR="http://127.0.0.1:8201" \
  -e VAULT_SKIP_VERIFY=true \
  -e VAULT_TOKEN="$token" \
  -i wisefido-vault vault secrets enable -path=pki pki || true

docker exec \
  -e VAULT_ADDR="http://127.0.0.1:8201" \
  -e VAULT_SKIP_VERIFY=true \
  -e VAULT_TOKEN="$token" \
  -i wisefido-vault vault secrets tune -max-lease-ttl=87600h pki

# ==============================
# 生成 Root CA（导出模式）
# ==============================
docker exec \
  -e VAULT_ADDR="http://127.0.0.1:8201" \
  -e VAULT_SKIP_VERIFY=true \
  -e VAULT_TOKEN="$token" \
  -i wisefido-vault vault write -format=json pki/root/generate/exported \
  common_name="WiseFido Root CA" organization="WiseFido Inc." country="US" ttl=87600h \
  > "${ROOT_DIR}/root_ca_export.json"

# ==============================
# 导出证书与私钥
# ==============================
jq -r .data.certificate "${ROOT_DIR}/root_ca_export.json" > "${ROOT_DIR}/root_ca.crt"
jq -r .data.private_key "${ROOT_DIR}/root_ca_export.json" > "${ROOT_DIR}/root_ca.key"

# ==============================
# 启用审计日志
# ==============================
docker exec \
  -e VAULT_ADDR="http://127.0.0.1:8201" \
  -e VAULT_SKIP_VERIFY=true \
  -e VAULT_TOKEN="$token" \
  -i wisefido-vault vault audit enable file file_path=/vault/logs/audit.log || true

echo "✅ Root CA 生成完成：${ROOT_DIR}/root_ca.crt"
echo "⚠️ 请立即离线备份 root_ca.key，并删除服务器明文副本！"


