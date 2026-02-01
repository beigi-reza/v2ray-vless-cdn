#!/bin/bash

# V2Ray Remove User Script
# This script removes a user from your V2Ray server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

CONFIG_FILE="v2ray/config.json"
BACKUP_FILE="v2ray/config.json.backup"

echo "=================================="
echo "V2Ray - Remove User"
echo "=================================="
echo ""

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Config file not found at $CONFIG_FILE${NC}"
    exit 1
fi

# List users first
echo "Current users:"
echo ""

python3 << 'EOF'
import json
import sys

try:
    with open('v2ray/config.json', 'r') as f:
        config = json.load(f)
    
    vless_inbound = None
    for inbound in config.get('inbounds', []):
        if inbound.get('protocol') == 'vless':
            vless_inbound = inbound
            break
    
    if not vless_inbound:
        print("Error: No vless inbound found")
        sys.exit(1)
    
    clients = vless_inbound.get('settings', {}).get('clients', [])
    
    if not clients:
        print("No users found.")
        sys.exit(0)
    
    for idx, client in enumerate(clients, 1):
        email = client.get('email', 'N/A')
        uuid = client.get('id', 'N/A')
        print(f"\033[1;33m[{idx}]\033[0m \033[0;36m{email}\033[0m")
        print(f"    UUID: {uuid}")
        print("")

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
EOF

if [ $? -ne 0 ]; then
    exit 1
fi

# Ask which user to remove
echo ""
read -p "Enter the number of the user to remove (or 'q' to quit): " USER_NUM

if [ "$USER_NUM" = "q" ] || [ "$USER_NUM" = "Q" ]; then
    echo "Cancelled."
    exit 0
fi

# Validate input
if ! [[ "$USER_NUM" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid input${NC}"
    exit 1
fi

# Create backup
echo ""
echo -e "${YELLOW}Creating backup...${NC}"
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo -e "${GREEN}Backup created: $BACKUP_FILE${NC}"
echo ""

# Remove user using Python
python3 << EOF
import json
import sys

try:
    user_num = int('$USER_NUM')
    
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
        print("Error: No vless inbound found")
        sys.exit(1)
    
    clients = vless_inbound.get('settings', {}).get('clients', [])
    
    if user_num < 1 or user_num > len(clients):
        print(f"Error: Invalid user number. Please choose between 1 and {len(clients)}")
        sys.exit(1)
    
    # Remove user
    removed_user = clients.pop(user_num - 1)
    
    # Write back to file
    with open('$CONFIG_FILE', 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"User removed: {removed_user.get('email', 'N/A')}")
    print(f"UUID: {removed_user.get('id', 'N/A')}")
    
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=================================="
    echo "User Removed Successfully!"
    echo "==================================${NC}"
    echo ""
    
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
    echo -e "${RED}Failed to remove user. Restoring backup...${NC}"
    cp "$BACKUP_FILE" "$CONFIG_FILE"
    echo -e "${YELLOW}Backup restored.${NC}"
    exit 1
fi