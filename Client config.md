# V2Ray Client Configuration Examples

## V2RayN (Windows)

1. Add a server manually:
   - Address: your-domain.com
   - Port: 443
   - User ID: [Your UUID]
   - Security: none
   - Network: ws
   - Path: /vmessws
   - TLS: tls
   - Host: your-domain.com
   - ALPN: h2,http/1.1

## V2RayNG (Android)

1. Click "+" → "Import config from clipboard" or "Manual input"
2. Fill in:
   - Alias: My V2Ray Server
   - Address: your-domain.com
   - Port: 443
   - ID: [Your UUID]
   - Security: none
   - Network: ws
   - Path: /vmessws
   - TLS: tls
   - Host: your-domain.com

## Shadowrocket (iOS)

1. Add Server
2. Type: Vless
3. Address: your-domain.com
4. Port: 443
5. UUID: [Your UUID]
6. TLS: On
7. Transport: WebSocket
8. Path: /vmessws
9. Host: your-domain.com

## Qv2ray (Linux/Windows/macOS)

JSON configuration:
```json
{
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "your-domain.com",
            "port": 443,
            "users": [
              {
                "id": "YOUR-UUID-HERE",
                "encryption": "none",
                "level": 0
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "serverName": "your-domain.com",
          "alpn": ["h2", "http/1.1"]
        },
        "wsSettings": {
          "path": "/vmessws",
          "headers": {
            "Host": "your-domain.com"
          }
        }
      }
    }
  ]
}
```

## Share Link

Use this format to share with other devices:

```
vless://[UUID]@[DOMAIN]:443?encryption=none&security=tls&type=ws&host=[DOMAIN]&path=%2Fvmessws&sni=[DOMAIN]#MyV2Ray
```

Replace:
- `[UUID]` with your generated UUID
- `[DOMAIN]` with your domain name

Example:
```
vless://12345678-1234-1234-1234-123456789abc@example.com:443?encryption=none&security=tls&type=ws&host=example.com&path=%2Fvmessws&sni=example.com#MyV2Ray
```

## Browser Extension (Chrome/Firefox)

1. Install SwitchyOmega
2. New Profile → SOCKS5
3. Server: 127.0.0.1
4. Port: 10808 (default V2Ray local port)
5. Connect your V2Ray client first

## Notes

- **encryption=none**: Vless uses TLS for encryption, no additional encryption needed
- **security=tls**: TLS must be enabled for CDN compatibility
- **type=ws**: WebSocket transport
- **path**: Must match server configuration (/vmessws)
- **sni**: Server Name Indication, should match your domain