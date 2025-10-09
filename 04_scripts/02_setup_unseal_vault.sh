#!/bin/bash
set -euo pipefail

# ============================================
# WiseFido Vault 解封脚本（最终稳定版）
# - 自动跳过 TLS 校验
# - 支持两次输入密钥
# - 防止变量未定义错误
# ============================================

CONTAINER="wisefido-vault"

echo "输入第一个 Unseal Key: "
read -rs KEY1
echo ""
echo "输入第二个 Unseal Key: "
read -rs KEY2
echo ""

echo "🔹 执行 Vault 解封操作..."
docker exec -e VAULT_SKIP_VERIFY=true -i $CONTAINER vault operator unseal "$KEY1"
docker exec -e VAULT_SKIP_VERIFY=true -i $CONTAINER vault operator unseal "$KEY2"

echo ""
echo "🔹 检查 Vault 状态..."
docker exec -e VAULT_SKIP_VERIFY=true -i $CONTAINER vault status

echo "✅ Vault 解封完成！"
