#!/bin/bash
set -euo pipefail
PROJECT_ROOT="/opt/00_WiseFido_CA_Project"

read -p "请输入 Vault Root Token: " token
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_TOKEN="$token"
export VAULT_SKIP_VERIFY=true   # ← 添加这行，跳过 TLS 校验

# 启用 Root PKI
docker exec -e VAULT_SKIP_VERIFY=true -i wisefido-vault vault secrets enable pki
docker exec -e VAULT_SKIP_VERIFY=true -i wisefido-vault vault secrets tune -max-lease-ttl=87600h pki

# 生成 Intermediate CSR
docker exec -i wisefido-vault vault write -field=csr pki_int/intermediate/generate/internal \
  common_name="WiseFido Intermediate CA" organization="WiseFido Inc." country="US" ttl=43800h \
  > "${INT_DIR}/intermediate.csr"

echo "✅ Intermediate CSR 生成：${INT_DIR}/intermediate.csr"
echo "🔹 请使用 Root CA 离线签署此 CSR..."