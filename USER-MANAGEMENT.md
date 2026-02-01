# V2Ray User Management Scripts

Complete set of scripts to manage users on your V2Ray server.

## Available Scripts

### 1. **manage-users.sh** (Recommended - All-in-One)
Interactive menu-based script with all user management features.

```bash
./manage-users.sh
```

**Features:**
- Add new users
- List all users  
- Remove users
- Show user details
- Backup configuration
- Restore configuration

### 2. **add-user.sh**
Quickly add a single user.

```bash
./add-user.sh
```

### 3. **list-users.sh**
Display all users with their connection strings.

```bash
./list-users.sh
```

### 4. **remove-user.sh**
Remove a user from the server.

```bash
./remove-user.sh
```

## Quick Start Guide

### Adding a New User

**Method 1: Interactive Menu (Recommended)**
```bash
./manage-users.sh
# Select option 1
```

**Method 2: Direct Script**
```bash
./add-user.sh
```

The script will:
1. Ask for user email/username
2. Generate a unique UUID
3. Add user to configuration
4. Display connection string
5. Optionally restart V2Ray container

### Listing All Users

```bash
./list-users.sh
```

Output example:
```
Total Users: 3

[1] john@example.com
    UUID: 12345678-1234-1234-1234-123456789abc
    Level: 0
    Connection: vless://12345678...

[2] jane@example.com
    UUID: 87654321-4321-4321-4321-cba987654321
    Level: 0
    Connection: vless://87654321...
```

### Removing a User

```bash
./remove-user.sh
# Or use the interactive menu
./manage-users.sh
# Select option 3
```

### Getting User Connection Details

**Method 1: Search by email or UUID**
```bash
./manage-users.sh
# Select option 4
# Enter email or UUID
```

**Method 2: List all users**
```bash
./list-users.sh
```

## Connection String Format

All scripts generate connection strings in this format:

```
vless://[UUID]@[DOMAIN]:443?encryption=none&security=tls&type=ws&host=[DOMAIN]&path=%2Fvmessws#[EMAIL]
```

You can:
- Copy this string and import it into your V2Ray client
- Generate a QR code from it
- Share it with users

## Configuration Backup & Restore

### Creating a Backup

```bash
./manage-users.sh
# Select option 5
```

Backups are saved as: `v2ray/config.backup.[TIMESTAMP].json`

### Restoring from Backup

```bash
./manage-users.sh
# Select option 6
# Select the backup file number
```

## Important Notes

1. **Automatic Backup**: All scripts automatically create a backup before making changes
2. **Container Restart**: Changes require restarting the V2Ray container to take effect
3. **UUID Generation**: Each user gets a unique UUID automatically
4. **Multiple Users**: You can add unlimited users to the same server

## Troubleshooting

### Script Can't Find Config File

Make sure you're running the script from the same directory as `docker-compose.yml`:

```bash
cd /path/to/v2ray
./manage-users.sh
```

### Changes Not Applied

Don't forget to restart the container:

```bash
docker-compose restart v2ray
```

### Python Not Found

Install Python 3:

```bash
sudo apt update
sudo apt install python3
```

### Permission Denied

Make scripts executable:

```bash
chmod +x *.sh
```

## Advanced Usage

### Batch Add Users

Create a text file with emails (one per line):
```
user1@example.com
user2@example.com
user3@example.com
```

Then use this command:
```bash
while read email; do
    echo "$email" | ./add-user.sh
done < users.txt
```

### Export All Users

```bash
./list-users.sh > all-users.txt
```

### Automated Backup

Add to crontab for daily backups:
```bash
crontab -e

# Add this line for daily backup at 2 AM
0 2 * * * cd /path/to/v2ray && cp v2ray/config.json v2ray/config.backup.$(date +\%Y\%m\%d).json
```

## Security Recommendations

1. **Unique Emails**: Use unique identifiers for each user
2. **Regular Cleanup**: Remove inactive users regularly
3. **Monitor Usage**: Check V2Ray logs for suspicious activity
4. **Backup Regularly**: Keep backups of your configuration
5. **Secure Scripts**: Don't share scripts containing your domain/config

## File Structure

```
.
├── manage-users.sh       # Main interactive menu
├── add-user.sh          # Add single user
├── list-users.sh        # List all users
├── remove-user.sh       # Remove user
├── v2ray/
│   ├── config.json      # Main configuration
│   └── config.backup.*  # Automatic backups
└── docker-compose.yml
```

## Examples

### Example: Adding Multiple Users

```bash
# Add user 1
./add-user.sh
# Enter: sales@company.com

# Add user 2  
./add-user.sh
# Enter: support@company.com

# List all users
./list-users.sh
```

### Example: User Lifecycle

```bash
# 1. Create user
./add-user.sh
> Enter email: newuser@example.com
> Generated UUID: abc-123-def
> Connection: vless://abc-123...

# 2. Share connection string with user

# 3. Later, check if user exists
./manage-users.sh
> Select: 4 (Show user details)
> Search: newuser

# 4. Remove when no longer needed
./remove-user.sh
> Select: 1 (if it's the first user)
```

## Support

If you encounter issues:
1. Check V2Ray logs: `docker-compose logs v2ray`
2. Verify config syntax: `cat v2ray/config.json | python3 -m json.tool`
3. Restore from backup if needed
4. Check that Python 3 is installed

## License

These scripts are provided as-is for managing your V2Ray server.