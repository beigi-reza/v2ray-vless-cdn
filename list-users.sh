#!/bin/bash

# V2Ray List Users Script
# This script lists all users in your V2Ray server

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

CONFIG_FILE="v2ray/config.json"

echo "=================================="
echo "V2Ray - List All Users"
echo "=================================="
echo ""

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Config file not found at $CONFIG_FILE${NC}"
    exit 1
fi

# List users using Python
python3 << 'EOF'
import json
import sys

try:
    # Read config
    with open('v2ray/config.json', 'r') as f:
        config = json.load(f)
    
    # Find vless inbound
    vless_inbound = None
    for inbound in config.get('inbounds', []):
        if inbound.get('protocol') == 'vless':
            vless_inbound = inbound
            break
    
    if not vless_inbound:
        print("Error: No vless inbound found in config")
        sys.exit(1)
    
    clients = vless_inbound.get('settings', {}).get('clients', [])
    
    if not clients:
        print("No users found.")
        sys.exit(0)
    
    # Get domain and path for connection strings
    domain = ""
    ws_path = ""
    
    stream_settings = vless_inbound.get('streamSettings', {})
    tls_settings = stream_settings.get('tlsSettings', {})
    ws_settings = stream_settings.get('wsSettings', {})
    
    domain = tls_settings.get('serverName', 'your-domain.com')
    ws_path = ws_settings.get('path', '/vmessws')
    
    print(f"\033[0;32mTotal Users: {len(clients)}\033[0m")
    print("")
    
    for idx, client in enumerate(clients, 1):
        email = client.get('email', 'N/A')
        uuid = client.get('id', 'N/A')
        level = client.get('level', 0)
        
        print(f"\033[1;33m[{idx}]\033[0m \033[0;36m{email}\033[0m")
        print(f"    UUID: {uuid}")
        print(f"    Level: {level}")
        
        # Generate connection string
        ws_path_encoded = ws_path.replace('/', '%2F')
        conn_string = f"vless://{uuid}@{domain}:443?encryption=none&security=tls&type=ws&host={domain}&path={ws_path_encoded}#{email}"
        print(f"    Connection: {conn_string}")
        print("")

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
EOF

if [ $? -ne 0 ]; then
    exit 1
fi

echo "=================================="