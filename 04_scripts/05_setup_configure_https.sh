#!/bin/bash
set -euo pipefail
PROJECT_ROOT="/opt/00_WiseFido_CA_Project"
CONF_DIR="${PROJECT_ROOT}/02_config"

read -p "请输入 Vault Root Token: " token
export VAULT_ADDR="https://ca.wisefido.work:8200"
export VAULT_TOKEN="$token"
export VAULT_SKIP_VERIFY=true

# 创建角色（允许签发服务器证书）
docker exec -i wisefido-vault vault write pki_int/roles/vault-server-role \
  allowed_domains="wisefido.work" allow_subdomains=true max_ttl="8760h"

# 签发服务器证书
docker exec -i wisefido-vault vault write -format=json pki_int/issue/vault-server-role \
  common_name="ca.wisefido.work" ttl="8760h" > "${CONF_DIR}/vault_server_cert.json"

jq -r .data.certificate "${CONF_DIR}/vault_server_cert.json" > "${CONF_DIR}/vault_cert.pem"
jq -r .data.private_key "${CONF_DIR}/vault_server_cert.json" > "${CONF_DIR}/vault_key.pem"

echo "✅ 新 HTTPS 证书生成完成，路径：${CONF_DIR}/vault_cert.pem"
echo "🔄 重启 Vault 容器以加载新证书..."
cd "${PROJECT_ROOT}/03_deploy"
docker compose restart vault
