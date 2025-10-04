#!/bin/bash
set -euo pipefail
PROJECT_ROOT="/opt/00_WiseFido_CA_Project"
ROOT_DIR="${PROJECT_ROOT}/05_opt/01_wisefido-ca/01_root"

read -p "请输入 Vault Root Token: " token
export VAULT_ADDR="https://ca.wisefido.work:8200"
export VAULT_TOKEN="$token"
export VAULT_SKIP_VERIFY=true  # 如因临时自签证书导致校验失败，先跳过；正式证书就去掉

# 启用 Root PKI
docker exec -i wisefido-vault vault secrets enable -path=pki pki
docker exec -i wisefido-vault vault secrets tune -max-lease-ttl=87600h pki

# 生成 Root（导出模式）
docker exec -i wisefido-vault vault write -format=json pki/root/generate/exported \
  common_name="WiseFido Root CA" organization="WiseFido Inc." country="US" ttl=87600h \
  > "${ROOT_DIR}/root_ca_export.json"

# 提取证书与私钥
jq -r .data.certificate "${ROOT_DIR}/root_ca_export.json" > "${ROOT_DIR}/root_ca.crt"
jq -r .data.private_key "${ROOT_DIR}/root_ca_export.json" > "${ROOT_DIR}/root_ca.key"

# 启用审计（CLI）
docker exec -i wisefido-vault sh -lc 'vault audit enable file file_path=/vault/logs/audit.log'

echo "✅ Root CA 生成完成：${ROOT_DIR}/root_ca.crt"
echo "⚠ 请将 root_ca.key 立即离线备份并从服务器删除明文副本。"
