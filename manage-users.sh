#!/bin/bash

# V2Ray User Management Script
# Comprehensive script to manage V2Ray users

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

CONFIG_FILE="v2ray/config.json"
BACKUP_FILE="v2ray/config.json.backup"

# Function to display menu
show_menu() {
    clear
    echo -e "${BLUE}=================================="
    echo "   V2Ray User Management"
    echo -e "==================================${NC}"
    echo ""
    echo "1) Add New User"
    echo "2) List All Users"
    echo "3) Remove User"
    echo "4) Show User Details"
    echo "5) Backup Configuration"
    echo "6) Restore Configuration"
    echo "0) Exit"
    echo ""
    echo -e "${BLUE}==================================${NC}"
}

# Function to add user
add_user() {
    echo -e "${GREEN}=== Add New User ===${NC}"
    echo ""
    
    read -p "Enter email/username for the new user: " USER_EMAIL
    
    if [ -z "$USER_EMAIL" ]; then
        echo -e "${RED}Error: Email cannot be empty${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    UUID=$(cat /proc/sys/kernel/random/uuid)
    
    echo ""
    echo -e "${GREEN}Generated UUID: $UUID${NC}"
    echo ""
    
    # Backup
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    
    # Add user
    python3 << EOF
import json
import sys

try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    
    vless_inbound = None
    for inbound in config.get('inbounds', []):
        if inbound.get('protocol') == 'vless':
            vless_inbound = inbound
            break
    
    if not vless_inbound:
        print("Error: No vless inbound found")
        sys.exit(1)
    
    new_user = {
        "id": "$UUID",
        "level": 0,
        "email": "$USER_EMAIL"
    }
    
    if 'clients' not in vless_inbound['settings']:
        vless_inbound['settings']['clients'] = []
    
    vless_inbound['settings']['clients'].append(new_user)
    
    with open('$CONFIG_FILE', 'w') as f:
        json.dump(config, f, indent=2)
    
    print("SUCCESS")

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}User added successfully!${NC}"
        echo ""
        echo "Email: $USER_EMAIL"
        echo "UUID: $UUID"
        echo ""
        
        DOMAIN=$(grep -oP '"serverName":\s*"\K[^"]+' "$CONFIG_FILE" | head -1)
        WS_PATH=$(grep -oP '"path":\s*"\K[^"]+' "$CONFIG_FILE" | head -1)
        
        if [ ! -z "$DOMAIN" ]; then
            echo "Connection String:"
            echo "vless://$UUID@$DOMAIN:443?encryption=none&security=tls&type=ws&host=$DOMAIN&path=%2F${WS_PATH#/}#$USER_EMAIL"
        fi
        
        echo ""
        read -p "Restart V2Ray container now? (y/n): " RESTART
        if [ "$RESTART" = "y" ]; then
            docker-compose restart v2ray
            echo -e "${GREEN}Container restarted!${NC}"
        fi
    else
        echo -e "${RED}Failed to add user${NC}"
        cp "$BACKUP_FILE" "$CONFIG_FILE"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to list users
list_users() {
    echo -e "${GREEN}=== All Users ===${NC}"
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
        
        ws_path_encoded = ws_path.replace('/', '%2F')
        conn_string = f"vless://{uuid}@{domain}:443?encryption=none&security=tls&type=ws&host={domain}&path={ws_path_encoded}#{email}"
        print(f"    Connection: {conn_string}")
        print("")

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
EOF
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to remove user
remove_user() {
    echo -e "${GREEN}=== Remove User ===${NC}"
    echo ""
    
    # List users first
    python3 << 'EOF'
import json
try:
    with open('v2ray/config.json', 'r') as f:
        config = json.load(f)
    
    vless_inbound = None
    for inbound in config.get('inbounds', []):
        if inbound.get('protocol') == 'vless':
            vless_inbound = inbound
            break
    
    clients = vless_inbound.get('settings', {}).get('clients', [])
    
    for idx, client in enumerate(clients, 1):
        email = client.get('email', 'N/A')
        uuid = client.get('id', 'N/A')
        print(f"\033[1;33m[{idx}]\033[0m \033[0;36m{email}\033[0m")
        print(f"    UUID: {uuid}")
        print("")
except Exception as e:
    print(f"Error: {e}")
EOF
    
    echo ""
    read -p "Enter user number to remove (0 to cancel): " USER_NUM
    
    if [ "$USER_NUM" = "0" ]; then
        return
    fi
    
    if ! [[ "$USER_NUM" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid input${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    
    python3 << EOF
import json
import sys

try:
    user_num = int('$USER_NUM')
    
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    
    vless_inbound = None
    for inbound in config.get('inbounds', []):
        if inbound.get('protocol') == 'vless':
            vless_inbound = inbound
            break
    
    clients = vless_inbound.get('settings', {}).get('clients', [])
    
    if user_num < 1 or user_num > len(clients):
        print(f"Error: Invalid user number")
        sys.exit(1)
    
    removed_user = clients.pop(user_num - 1)
    
    with open('$CONFIG_FILE', 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"Removed: {removed_user.get('email', 'N/A')}")
    
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}User removed successfully!${NC}"
        
        read -p "Restart V2Ray container now? (y/n): " RESTART
        if [ "$RESTART" = "y" ]; then
            docker-compose restart v2ray
            echo -e "${GREEN}Container restarted!${NC}"
        fi
    else
        echo -e "${RED}Failed to remove user${NC}"
        cp "$BACKUP_FILE" "$CONFIG_FILE"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to show user details
show_user_details() {
    echo -e "${GREEN}=== User Details ===${NC}"
    echo ""
    
    read -p "Enter email or UUID to search: " SEARCH
    
    python3 << EOF
import json
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    
    vless_inbound = None
    for inbound in config.get('inbounds', []):
        if inbound.get('protocol') == 'vless':
            vless_inbound = inbound
            break
    
    clients = vless_inbound.get('settings', {}).get('clients', [])
    
    stream_settings = vless_inbound.get('streamSettings', {})
    tls_settings = stream_settings.get('tlsSettings', {})
    ws_settings = stream_settings.get('wsSettings', {})
    
    domain = tls_settings.get('serverName', 'your-domain.com')
    ws_path = ws_settings.get('path', '/vmessws')
    
    found = False
    for client in clients:
        email = client.get('email', '')
        uuid = client.get('id', '')
        
        if '$SEARCH' in email or '$SEARCH' in uuid:
            found = True
            print(f"\033[0;36mEmail:\033[0m {email}")
            print(f"\033[0;36mUUID:\033[0m {uuid}")
            print(f"\033[0;36mLevel:\033[0m {client.get('level', 0)}")
            print("")
            ws_path_encoded = ws_path.replace('/', '%2F')
            conn_string = f"vless://{uuid}@{domain}:443?encryption=none&security=tls&type=ws&host={domain}&path={ws_path_encoded}#{email}"
            print(f"\033[0;36mConnection String:\033[0m")
            print(f"{conn_string}")
            print("")
    
    if not found:
        print("No matching user found.")
        
except Exception as e:
    print(f"Error: {e}")
EOF
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to backup config
backup_config() {
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_NAME="v2ray/config.backup.$TIMESTAMP.json"
    
    cp "$CONFIG_FILE" "$BACKUP_NAME"
    
    echo -e "${GREEN}Configuration backed up to: $BACKUP_NAME${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# Function to restore config
restore_config() {
    echo -e "${GREEN}=== Restore Configuration ===${NC}"
    echo ""
    echo "Available backups:"
    echo ""
    
    ls -1 v2ray/config.backup.*.json 2>/dev/null | nl
    
    echo ""
    read -p "Enter backup number to restore (0 to cancel): " BACKUP_NUM
    
    if [ "$BACKUP_NUM" = "0" ]; then
        return
    fi
    
    BACKUP_FILE=$(ls -1 v2ray/config.backup.*.json 2>/dev/null | sed -n "${BACKUP_NUM}p")
    
    if [ -z "$BACKUP_FILE" ]; then
        echo -e "${RED}Invalid selection${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    cp "$BACKUP_FILE" "$CONFIG_FILE"
    echo -e "${GREEN}Configuration restored from: $BACKUP_FILE${NC}"
    
    read -p "Restart V2Ray container now? (y/n): " RESTART
    if [ "$RESTART" = "y" ]; then
        docker-compose restart v2ray
        echo -e "${GREEN}Container restarted!${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice: " choice
    
    case $choice in
        1) add_user ;;
        2) list_users ;;
        3) remove_user ;;
        4) show_user_details ;;
        5) backup_config ;;
        6) restore_config ;;
        0) 
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            sleep 1
            ;;
    esac
done