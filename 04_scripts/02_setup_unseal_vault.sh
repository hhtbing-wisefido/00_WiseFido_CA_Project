#!/bin/bash
set -euo pipefail

read -p "输入第一个 Unseal Key: " key1
read -p "输入第二个 Unseal Key: " key2

docker exec -e VAULT_SKIP_VERIFY=true -i wisefido-vault vault operator unseal "$KEY1"
docker exec -e VAULT_SKIP_VERIFY=true -i wisefido-vault vault operator unseal "$KEY2"


docker exec -i wisefido-vault vault status
echo "✅ Vault 已成功解封。"
