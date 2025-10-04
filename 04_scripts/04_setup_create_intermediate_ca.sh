#!/bin/bash
set -euo pipefail
PROJECT_ROOT="/opt/00_WiseFido_CA_Project"
INT_DIR="${PROJECT_ROOT}/05_opt/01_wisefido-ca/02_intermediate"

read -p "请输入 Vault Root Token: " token
export VAULT_ADDR="https://ca.wisefido.work:8200"
export VAULT_TOKEN="$token"
export VAULT_SKIP_VERIFY=true

# 启用 Intermediate PKI 引擎
docker exec -i wisefido-vault vault secrets enable -path=pki_int pki
docker exec -i wisefido-vault vault secrets tune -max-lease-ttl=43800h pki_int

# 生成 Intermediate CSR
docker exec -i wisefido-vault vault write -field=csr pki_int/intermediate/generate/internal \
  common_name="WiseFido Intermediate CA" organization="WiseFido Inc." country="US" ttl=43800h \
  > "${INT_DIR}/intermediate.csr"

echo "✅ Intermediate CSR 生成：${INT_DIR}/intermediate.csr"
echo "🔹 请使用 Root CA 离线签署此 CSR..."