# 02_config/01_vault.hcl  ——— 统一与卷 00 目录树

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/vault/config/vault_cert.pem"
  tls_key_file  = "/vault/config/vault_key.pem"
}

storage "file" {
  path = "/vault/data"
}

api_addr = "https://ca.wisefido.work:8200"
ui       = true
log_level = "info"

disable_mlock = true
max_lease_ttl     = "87600h"
default_lease_ttl = "43800h"

# 审计请用 CLI 在脚本中启用，避免 HCL 冲突
