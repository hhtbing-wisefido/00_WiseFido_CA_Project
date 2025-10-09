# ============================
# WiseFido Vault 主配置文件
# 双监听架构：外部 HTTPS + 内部 HTTP
# ============================

# 外部访问：通过域名 ca.wisefido.work (HTTPS)
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = 0
  tls_cert_file = "/vault/config/vault_cert.pem"
  tls_key_file  = "/vault/config/vault_key.pem"
}

# 内部访问：Vault CLI 使用回环 HTTP
listener "tcp" {
  address     = "127.0.0.1:8201"
  tls_disable = 1
}

# Vault 对外广播（UI、API）
api_addr     = "https://ca.wisefido.work:8200"
cluster_addr = "http://127.0.0.1:8201"

# 数据存储
storage "file" {
  path = "/vault/data"
}

# 启用 Web UI
ui = true

# 允许在容器环境运行
disable_mlock = true

