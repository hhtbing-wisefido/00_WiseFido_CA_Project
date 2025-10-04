#!/bin/bash
set -euo pipefail

read -p "输入第一个 Unseal Key: " key1
read -p "输入第二个 Unseal Key: " key2

docker exec -i wisefido-vault vault operator unseal "$key1"
docker exec -i wisefido-vault vault operator unseal "$key2"

docker exec -i wisefido-vault vault status
echo "✅ Vault 已解封。"
