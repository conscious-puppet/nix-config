# Vaultwarden HTTPS

Vaultwarden serves HTTPS on `0.0.0.0:8222` via Rocket's native TLS.

## URLs

| From        | URL                               |
|-------------|-----------------------------------|
| This Mac    | `https://localhost:8222`          |
| LAN / Phone | `https://<IP>:8222` (use your IP) |

## Certificates

Auto-generated on first vaultwarden start into `~/.vaultwarden/ssl/`:

| File               | Purpose                             |
|--------------------|-------------------------------------|
| `ca-cert.pem`      | Install on phone/mac                |
| `server-chain.pem` | Server cert + CA — served by Rocket |
| `*-key.pem`        | Private keys — never leave this Mac |

Nothing in `ssl/` is committed to git.

## Trust the CA

### macOS

```bash
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  ~/.vaultwarden/ssl/ca-cert.pem
```

### Android

1. Copy `~/.vaultwarden/ssl/ca-cert.pem` to your phone
2. Settings → Security → Encryption & credentials → Install certificate → **CA certificate**
3. Select the file and confirm
4. In the Bitwarden app, use your Mac's IP: `https://<IP>:8222`

## Regenerate

If your IP changes or certs expire:

```bash
rm -rf ~/.vaultwarden/ssl/
darwin-rebuild switch --flake .
sudo launchctl kickstart -k system/org.nixos.vaultwarden
```

## Common issues

- **Connection refused**: `sudo launchctl list | grep vaultwarden`
- **Certificate error on phone**: Ensure the CA is installed as a **CA certificate** (not VPN/Wi-Fi cert)
- **Bitwarden app fails**: Restart vaultwarden after regenerating certs; use IP address, not hostname
