#!/bin/bash

# V2Ray Add User Script
# This script adds a new user to your V2Ray server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CONFIG_FILE="v2ray/config.json"
BACKUP_FILE="v2ray/config.json.backup"

echo "=================================="
echo "V2Ray - Add New User"
echo "=================================="
echo ""

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Config file not found at $CONFIG_FILE${NC}"
    echo "Please run this script from the same directory as docker-compose.yml"
    exit 1
fi

# Create backup
echo -e "${YELLOW}Creating backup...${NC}"
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo -e "${GREEN}Backup created: $BACKUP_FILE${NC}"
echo ""

# Get user details
read -p "Enter email/username for the new user (e.g., user@example.com): " USER_EMAIL

# Generate UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

echo ""
echo -e "${GREEN}Generated UUID: $UUID${NC}"
echo ""

# Add user to config using Python
python3 << EOF
import json
import sys

try:
    # Read config
    with open('$CONFIG_FILE', 'r') as f:
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
    
    # Add new user
    new_user = {
        "id": "$UUID",
        "level": 0,
        "email": "$USER_EMAIL"
    }
    
    if 'clients' not in vless_inbound['settings']:
        vless_inbound['settings']['clients'] = []
    
    vless_inbound['settings']['clients'].append(new_user)
    
    # Write back to file
    with open('$CONFIG_FILE', 'w') as f:
        json.dump(config, f, indent=2)
    
    print("User added successfully!")
    
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=================================="
    echo "User Added Successfully!"
    echo "==================================${NC}"
    echo ""
    echo "User Details:"
    echo "-------------"
    echo "Email: $USER_EMAIL"
    echo "UUID: $UUID"
    echo ""
    
    # Get domain from config
    DOMAIN=$(grep -oP '"serverName":\s*"\K[^"]+' "$CONFIG_FILE" | head -1)
    WS_PATH=$(grep -oP '"path":\s*"\K[^"]+' "$CONFIG_FILE" | head -1)
    
    if [ ! -z "$DOMAIN" ]; then
        echo "Connection String:"
        echo "------------------"
        echo "vless://$UUID@$DOMAIN:443?encryption=none&security=tls&type=ws&host=$DOMAIN&path=%2F${WS_PATH#/}#$USER_EMAIL"
        echo ""
    fi
    
    # Ask to restart
    echo -e "${YELLOW}To apply changes, you need to restart the V2Ray container.${NC}"
    read -p "Do you want to restart now? (y/n): " RESTART
    
    if [ "$RESTART" = "y" ] || [ "$RESTART" = "Y" ]; then
        echo ""
        echo "Restarting V2Ray container..."
        docker-compose restart v2ray
        echo -e "${GREEN}Container restarted successfully!${NC}"
    else
        echo ""
        echo -e "${YELLOW}Remember to restart the container manually:${NC}"
        echo "  docker-compose restart v2ray"
    fi
    
    echo ""
    echo -e "${GREEN}Done!${NC}"
else
    echo ""
    echo -e "${RED}Failed to add user. Restoring backup...${NC}"
    cp "$BACKUP_FILE" "$CONFIG_FILE"
    echo -e "${YELLOW}Backup restored.${NC}"
    exit 1
fi