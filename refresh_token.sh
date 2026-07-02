#!/bin/bash
# SimpleMem token refresh helper
# Run this when your JWT token expires (~30 days).
# Updates both VS Code .vscode/mcp.json and Zed ~/.config/zed/settings.json.

set -e

VSCODE_MCP="/home/sanchitbhise/Projects/Buildit/.vscode/mcp.json"
ZED_SETTINGS="$HOME/.config/zed/settings.json"
CONTINUE_CFG="$HOME/.continue/config.yaml"
API="http://localhost:8000"

echo "==> Checking SimpleMem container..."
if ! docker ps --filter name=simplemem --filter status=running | grep -q simplemem; then
  echo "    Container not running — starting..."
  cd "$(dirname "$0")"
  docker compose --env-file .env up -d
  sleep 3
fi

echo "==> Registering to get a fresh token..."
RESPONSE=$(curl -s -X POST "$API/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"openrouter_api_key": "ollama-placeholder-key"}')

SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))")
if [ "$SUCCESS" != "True" ]; then
  echo "ERROR: Registration failed — $RESPONSE"
  exit 1
fi

TOKEN=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
echo "    Token: ${TOKEN:0:40}..."

echo "==> Updating VS Code mcp.json..."
python3 - "$VSCODE_MCP" "$TOKEN" <<'PYEOF'
import sys, json, re

path, token = sys.argv[1], sys.argv[2]
with open(path) as f:
    content = f.read()

# Replace the Bearer token value
new_content = re.sub(r'Bearer [A-Za-z0-9._-]+', f'Bearer {token}', content)
with open(path, 'w') as f:
    f.write(new_content)
print("    Done.")
PYEOF

echo "==> Updating Zed settings.json..."
python3 - "$ZED_SETTINGS" "$TOKEN" <<'PYEOF'
import sys, re

path, token = sys.argv[1], sys.argv[2]
with open(path) as f:
    content = f.read()

new_content = re.sub(r'Bearer [A-Za-z0-9._-]+', f'Bearer {token}', content)
with open(path, 'w') as f:
    f.write(new_content)
print("    Done.")
PYEOF

echo "==> Updating Continue.dev config.yaml (SSE URL token)..."
python3 - "$CONTINUE_CFG" "$TOKEN" <<'PYEOF'
import sys, re

path, token = sys.argv[1], sys.argv[2]
with open(path) as f:
    content = f.read()

# Update both Bearer headers AND ?token= query params in SSE URLs
new_content = re.sub(r'Bearer [A-Za-z0-9._-]+', f'Bearer {token}', content)
new_content = re.sub(r'\?token=[A-Za-z0-9._-]+', f'?token={token}', new_content)
with open(path, 'w') as f:
    f.write(new_content)
print("    Done.")
PYEOF

echo ""
echo "✅  Token refreshed in both IDEs. Restart the MCP server in each IDE to pick it up."
