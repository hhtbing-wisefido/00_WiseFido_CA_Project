#!/bin/bash
set -euo pipefail

echo "🔍 正在检测 Vault Listener 状态..."
echo "------------------------------------"

# 检查容器是否运行
if ! docker ps | grep -q wisefido-vault; then
  echo "❌ Vault 容器未运行，请先执行："
  echo "   cd /opt/00_WiseFido_CA_Project/03_deploy && docker compose up -d"
  exit 1
fi

# 检查端口监听
echo "🔹 检查容器内监听端口..."
docker exec -it wisefido-vault netstat -tuln | grep 820 || true

# 检查 Vault 是否监听 8200 和 8201
PORTS=$(docker exec -it wisefido-vault netstat -tuln | grep 820 | awk '{print $4}' | sed 's/::://g')
HAS_8200=$(echo "$PORTS" | grep -c "8200" || true)
HAS_8201=$(echo "$PORTS" | grep -c "8201" || true)

if [[ "$HAS_8200" -ge 1 && "$HAS_8201" -ge 1 ]]; then
  echo "✅ Vault 已启用双监听 (HTTPS:8200 + HTTP:8201)"
else
  echo "❌ Vault 监听不完整："
  if [[ "$HAS_8200" -eq 0 ]]; then echo "  - 缺少 8200 (外部 HTTPS)"; fi
  if [[ "$HAS_8201" -eq 0 ]]; then echo "  - 缺少 8201 (内部 HTTP)"; fi
  echo "⚙️ 请检查并重新加载配置文件：/opt/00_WiseFido_CA_Project/02_config/01_vault.hcl"
  exit 1
fi

# 检查内部接口健康
echo "🔹 检查 Vault 内部 HTTP (8201) 通信..."
if docker exec -it wisefido-vault curl -s http://127.0.0.1:8201/v1/sys/health >/dev/null 2>&1; then
  echo "✅ 内部接口 (http://127.0.0.1:8201) 可访问。"
else
  echo "❌ 无法访问 Vault 内部接口 (127.0.0.1:8201)。"
  echo "⚠️ Vault 可能未完全加载或正在重启。"
  exit 1
fi

# 检查外部接口健康
echo "🔹 检查 Vault 外部 HTTPS (8200) 通信..."
if curl -sk https://ca.wisefido.work:8200/v1/sys/health >/dev/null 2>&1; then
  echo "✅ 外部接口 (https://ca.wisefido.work:8200) 可访问。"
else
  echo "⚠️ 外部接口暂时不可达。请检查证书或防火墙规则。"
fi

echo "------------------------------------"
echo "🎉 Vault 监听检测完成。系统配置正常。"
