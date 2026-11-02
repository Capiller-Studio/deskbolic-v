# Bare-Metal & Systemd Production Deployment

This directory contains production-tested configurations copied directly from Deskbolic's high-performance Hetzner AX42 Proxmox cluster.

These configurations are provided as a battle-tested reference for organizations running bare-metal Linux servers, Proxmox VE, or traditional VPS environments instead of Docker.

---

## Directory Structure

```
deploy/
├── caddy/
│   └── Caddyfile.production       # Live production edge proxy with Cloudflare DNS TLS & On-Demand SSL
└── systemd/
    ├── deskbolic-puma.service     # Main Rails Dashboard (Port 3001)
    ├── deskbolic-widget.service   # Customer Live Chat Widget (Port 3006)
    ├── deskbolic-helpbolic.service# Customer Help Center & Knowledge Base (Port 3003)
    ├── deskbolic-gateway.service  # Inbound & Outbound API Gateway (Port 3005)
    ├── deskbolic-sidekiq.service  # Multithreaded Background Job Processor
    ├── anycable-rpc.service       # AnyCable Rails gRPC Service (Port 50051)
    └── anycable-go.service        # High-concurrency WebSocket Daemon (Port 8080)
```

---

## Production Port Mapping

| Service | Internal Port | Public Subdomain | Role |
| :--- | :--- | :--- | :--- |
| **Deskbolic Web** | `3001` | `deskbolic.app`, `*.deskbolic.app` | Agent portal & core API |
| **Widget** | `3006` | `widget.deskbolic.com` | Embeddable customer chat widget |
| **Helpbolic** | `3003` | `helpbolic.com`, `*.helpbolic.com` | Public knowledge base & docs |
| **Gateway** | `3005` | `api.deskbolic.com` | External REST API ingress |
| **AnyCable-Go** | `8080` | `ws.deskbolic.com` | WebSocket connection holder |
| **AnyCable-RPC** | `50051` | *Internal only* | Rails gRPC auth & channel handler |
| **Sidekiq** | *N/A* | *Internal only* | Async job execution |
| **PostgreSQL 17** | `5432` | *Internal only* | Primary & European sharded DBs |
| **Redis 7** | `6379` | *Internal only* | Cache (0), Sidekiq (1), Pub/Sub (2) |

---

## Installing Systemd Services

1. Copy the service unit files to `/etc/systemd/system/`:
   ```bash
   sudo cp deploy/systemd/*.service /etc/systemd/system/
   ```

2. Adjust paths, user (`deploy`), and environment files in each unit to match your server layout.

3. Reload systemd daemon and enable services:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now deskbolic-puma deskbolic-widget deskbolic-helpbolic deskbolic-gateway deskbolic-sidekiq anycable-rpc anycable-go
   ```

4. Verify status:
   ```bash
   sudo systemctl status deskbolic-puma
   ```

---

## Installing Caddy Edge Proxy

1. Install [Caddy](https://caddyserver.com/docs/install) on your edge or gateway server.
2. If using Cloudflare DNS for automated wildcard SSL, install the Caddy binary with the `caddy-dns/cloudflare` plugin:
   ```bash
   xcaddy build --with github.com/caddy-dns/cloudflare
   ```
3. Copy `deploy/caddy/Caddyfile.production` to `/etc/caddy/Caddyfile`:
   ```bash
   sudo cp deploy/caddy/Caddyfile.production /etc/caddy/Caddyfile
   ```
4. Replace internal IPs (`10.0.0.x`) with your server's LAN or loopback IP (`127.0.0.1`), export `CLOUDFLARE_API_TOKEN`, and reload Caddy:
   ```bash
   sudo systemctl reload caddy
   ```
