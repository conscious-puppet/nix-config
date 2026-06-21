# Vaultwarden via Tailscale Serve

Vaultwarden runs on plain HTTP at `127.0.0.1:8222` and is exposed over HTTPS via Tailscale Serve at your tailnet address.

## Prerequisites

- Tailscale must be installed, authenticated, and running on this Mac
- You must be on the tailnet to access Vaultwarden

## URL

Access Vaultwarden at your tailnet address, e.g.:

```
https://puppeteer.taile4816.ts.net
```

The exact hostname is your machine's Tailscale DNS name (`tailscale status` to check).

## How it works

Two launchd daemons run simultaneously:

| Daemon | Role |
|--------|------|
| `org.nixos.vaultwarden` | Runs Vaultwarden on `127.0.0.1:8222` (HTTP, loopback only) |
| `org.nixos.tailscale-vaultwarden` | Proxies `https://<tailnet>` → `http://127.0.0.1:8222` via Tailscale Serve |

Tailscale acquires and renews a real TLS certificate automatically. No self-signed certs or manual CA installation on devices.

## Restart after changes

```bash
darwin-rebuild switch --flake .
sudo launchctl kickstart -k system/org.nixos.vaultwarden
sudo launchctl kickstart -k system/org.nixos.tailscale-vaultwarden
```

## Common issues

- **Connection refused**: Check both daemons are running:
  ```bash
  sudo launchctl list | grep -E '(vaultwarden|tailscale)'
  ```
- **Tailscale URL not resolving**: Ensure Tailscale is connected (`tailscale status`) and check your DNS name with `tailscale status --json | jq -r '.Self.DNSName'`
- **HTTPS error in browser**: Tailscale cert provisioning can take a minute after the serve daemon starts; check `/tmp/tailscale-vaultwarden.log`
