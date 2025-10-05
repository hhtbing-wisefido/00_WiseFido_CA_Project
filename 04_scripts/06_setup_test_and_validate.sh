#!/bin/bash
set -euo pipefail
PROJECT_ROOT="/opt/00_WiseFido_CA_Project"

echo "🔍 Vault 运行状态检查..."
docker exec -i wisefido-vault vault status || { echo "❌ Vault 未运行"; exit 1; }

echo "🔍 Root/Intermediate 文件检查..."
test -f "${PROJECT_ROOT}/05_opt/01_wisefido-ca/01_root/root_ca.crt" || { echo "❌ Root CA 缺失"; exit 1; }
test -f "${PROJECT_ROOT}/05_opt/01_wisefido-ca/02_intermediate/intermediate.crt" || { echo "❌ Intermediate 缺失"; exit 1; }

echo "🔍 测试 Vault HTTPS 接口..."
curl -sk --cacert "${PROJECT_ROOT}/05_opt/01_wisefido-ca/01_root/root_ca.crt" \
  https://ca.wisefido.work:8200/v1/sys/health | jq . > "${PROJECT_ROOT}/05_opt/test_vault_health.json"

echo "🔍 验证证书链..."
openssl verify -CAfile "${PROJECT_ROOT}/05_opt/01_wisefido-ca/01_root/root_ca.crt" \
  "${PROJECT_ROOT}/05_opt/01_wisefido-ca/02_intermediate/intermediate.crt"

echo "🔍 审计日志验证..."
docker exec -i wisefido-vault sh -lc 'test -f /vault/logs/audit.log && echo "✅ 审计日志已启用" || echo "⚠ 未启用审计"'

echo "🔍 测试设备证书签发接口可用性（仅检查角色列表）..."
curl -sk --header "X-Vault-Token: <root_token>" \
  https://ca.wisefido.work:8200/v1/pki_int/roles | jq . > "${PROJECT_ROOT}/05_opt/test_vault_roles.json"

echo "✅ 所有测试完成，结果已写入："
echo "   - ${PROJECT_ROOT}/05_opt/test_vault_health.json"
echo "   - ${PROJECT_ROOT}/05_opt/test_vault_roles.json"