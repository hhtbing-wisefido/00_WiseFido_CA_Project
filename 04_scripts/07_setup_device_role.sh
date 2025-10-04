#!/bin/bash
set -euo pipefail

export VAULT_ADDR="https://ca.wisefido.work:8200"
export VAULT_TOKEN="<root_token>"

docker exec -i wisefido-vault vault write pki_int/roles/device-role \
  allowed_domains="wisefido.work" \
  allow_subdomains=true \
  allow_any_name=true \
  key_type="rsa" key_bits=2048 \
  max_ttl="26280h"  # 3年
