# =============================
# WiseFido Vault 主配置文件 (v2.0)
# =============================

ui = true
log_level = "info"

# 🔐 HTTPS 监听配置
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/vault/config/vault_cert.pem"
  tls_key_file  = "/vault/config/vault_key.pem"
}

# 💾 存储引擎（文件型）
storage "file" {
  path = "/vault/data"
}

# 🌐 API 地址配置（与 Compose 环境变量一致）
api_addr = "https://ca.wisefido.work:8200"
cluster_addr = "https://127.0.0.1:8201"

