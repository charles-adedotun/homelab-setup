# Homelab Setup

Production-grade Docker homelab with automated DNS, macvlan networking, and WireGuard VPN.

## Why This Exists

You're an SRE who wants a local environment that mirrors production infrastructure. Not a toy setup with port conflicts and bridge networks, but a real network where containers get their own IPs on your LAN, DNS resolution works correctly, and you can access everything securely from anywhere via VPN.

This is that setup. Everything runs in Docker, configured via Docker Compose, with proper networking that behaves like production. No Kubernetes complexity when you don't need it. Just reliable services with production-like networking.

## What You Get

- **macvlan Networking**: Containers get real IPs on your LAN (no port mapping chaos)
- **Automated DNS**: Pi-hole or AdGuard for network-wide ad blocking and local DNS resolution
- **WireGuard VPN**: Secure remote access to your homelab from anywhere
- **Service Management**: All services defined in Docker Compose with dependency management
- **Make-based Workflow**: Simple commands to start, stop, and manage everything
- **Persistent Storage**: Proper volume management for data persistence
- **Automatic Restarts**: Services recover automatically on failure or reboot

## Tech Stack

- **Shell/Bash**: Automation scripts and setup utilities
- **Docker**: Container runtime
- **Docker Compose**: Service orchestration
- **WireGuard**: VPN server
- **DNS**: Pi-hole or AdGuard Home
- **Make**: Task runner for common operations

## Network Architecture

### macvlan Setup

Traditional Docker bridge networks cause problems:
- Port conflicts between services
- Complex port mapping
- Services can't communicate using standard ports
- External devices can't reach containers directly

macvlan solves this by giving each container a real IP on your LAN:

```
Router (192.168.1.1)
    │
    ├─ Host Machine (192.168.1.10)
    ├─ Pi-hole Container (192.168.1.11)
    ├─ WireGuard Container (192.168.1.12)
    ├─ App Container 1 (192.168.1.13)
    └─ App Container 2 (192.168.1.14)
```

Each container is a first-class citizen on your network.

### DNS Flow

```
Device on LAN
    ↓
Pi-hole (192.168.1.11)
    ↓
Local records (homelab.local) → Returns container IPs
External domains → Upstream DNS (1.1.1.1, 8.8.8.8)
Ads/Trackers → Blocked (returns 0.0.0.0)
```

Configure your router's DHCP to use Pi-hole as DNS, and every device on your network gets ad blocking and can resolve `service.homelab.local` to container IPs.

### VPN Access

```
Remote Device
    ↓
Internet
    ↓
WireGuard Server (Public IP / DDNS)
    ↓
Encrypted Tunnel
    ↓
Homelab Network (192.168.1.0/24)
    ↓
Access all services via local IPs or DNS names
```

## Quick Start

### Prerequisites

- Linux host (Ubuntu 22.04+ recommended) or macOS with Docker Desktop
- Docker 24.0+ and Docker Compose v2
- Static IP for your host machine
- Router access for DHCP/DNS configuration (optional but recommended)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/homelab-setup.git
cd homelab-setup

# Copy example config
cp .env.example .env

# Edit .env with your network settings
nano .env
```

Configure these critical variables in `.env`:

```bash
# Your LAN subnet
LAN_SUBNET=192.168.1.0/24

# Gateway (your router)
LAN_GATEWAY=192.168.1.1

# IP range for containers (must be outside DHCP range)
CONTAINER_IP_START=192.168.1.50
CONTAINER_IP_END=192.168.1.100

# DNS settings
PIHOLE_IP=192.168.1.11
UPSTREAM_DNS_1=1.1.1.1
UPSTREAM_DNS_2=8.8.8.8

# Domain for local services
LOCAL_DOMAIN=homelab.local

# WireGuard
WIREGUARD_IP=192.168.1.12
WIREGUARD_PUBLIC_IP=your.public.ip.or.ddns
```

### Deploy the Stack

```bash
# Create macvlan network
make network-setup

# Start core services (DNS, VPN)
make core-up

# Start all services
make up

# Check status
make status

# View logs
make logs SERVICE=pihole
```

### Configure DNS

1. Access Pi-hole admin panel: `http://192.168.1.11/admin`
2. Default password is in `.env` (PIHOLE_PASSWORD)
3. Add local DNS records for your services:
   - `pihole.homelab.local` → `192.168.1.11`
   - `vpn.homelab.local` → `192.168.1.12`
4. Point your router's DHCP DNS to `192.168.1.11`

### Set Up WireGuard VPN

```bash
# Generate client config
make wireguard-client NAME=laptop

# QR code for mobile devices
make wireguard-qr NAME=phone

# Client configs are in ./wireguard/clients/
```

Import the config into your WireGuard client and connect. You'll have full access to your homelab network remotely.

## Service Management

### Common Commands

```bash
# Start everything
make up

# Stop everything
make down

# Restart a specific service
make restart SERVICE=pihole

# View logs (follow mode)
make logs SERVICE=wireguard

# Check container status
make status

# Update all containers
make update

# Backup volumes
make backup

# Restore from backup
make restore BACKUP=2025-12-10
```

### Adding New Services

1. Create a new compose file in `services/your-service.yml`:

```yaml
version: '3.9'

services:
  your-service:
    image: your/image:latest
    container_name: your-service
    networks:
      homelab:
        ipv4_address: 192.168.1.15
    volumes:
      - ./data/your-service:/data
    environment:
      - SOME_VAR=value
    restart: unless-stopped

networks:
  homelab:
    external: true
    name: homelab_network
```

2. Add to `docker-compose.yml`:

```yaml
include:
  - services/pihole.yml
  - services/wireguard.yml
  - services/your-service.yml
```

3. Deploy:

```bash
make up
```

## Directory Structure

```
homelab-setup/
├── docker-compose.yml          # Main compose orchestration
├── .env                        # Configuration variables
├── Makefile                    # Management commands
├── services/                   # Individual service definitions
│   ├── pihole.yml
│   ├── wireguard.yml
│   └── ...
├── data/                       # Persistent volumes
│   ├── pihole/
│   ├── wireguard/
│   └── ...
├── scripts/                    # Automation scripts
│   ├── network-setup.sh
│   ├── backup.sh
│   └── restore.sh
└── docs/                       # Additional documentation
    ├── networking.md
    ├── troubleshooting.md
    └── services.md
```

## Troubleshooting

### Containers Can't Get IPs

Check if your IP range conflicts with DHCP:

```bash
# Reserve IPs in router DHCP settings
# Or use a range outside DHCP allocation
```

### Can't Access Containers from Host

macvlan limitation - host can't reach containers directly. Solution:

```bash
# Create a macvlan interface on host
sudo ip link add homelab-shim link eth0 type macvlan mode bridge
sudo ip addr add 192.168.1.254/32 dev homelab-shim
sudo ip link set homelab-shim up
sudo ip route add 192.168.1.50/28 dev homelab-shim
```

Or use the provided script:

```bash
make host-access
```

### DNS Not Resolving

1. Check Pi-hole is running: `docker ps | grep pihole`
2. Verify network config: `docker network inspect homelab_network`
3. Test DNS: `dig @192.168.1.11 google.com`
4. Check upstream DNS in Pi-hole settings

### WireGuard Won't Connect

1. Verify UDP port forwarding on router (default 51820)
2. Check public IP/DDNS is correct in config
3. Ensure firewall allows WireGuard traffic
4. Test connectivity: `wg show` on server

## Future Enhancements

- **Monitoring Stack**: Add Prometheus, Grafana, and Loki for observability across all services
- **Kubernetes Cluster**: Expand to K3s for container orchestration when complexity justifies it
- **GitOps Workflow**: Use FluxCD or ArgoCD to manage configuration via Git
- **Automated Backups**: Scheduled backups to S3-compatible storage with retention policies
- **Certificate Management**: Automated TLS with Let's Encrypt and Traefik reverse proxy
- **Hardware Monitoring**: Integration with sensors for temperature, power usage, and disk health

## Security Considerations

- Change default passwords in `.env` before deploying
- Use strong WireGuard pre-shared keys
- Keep containers updated regularly (`make update`)
- Restrict SSH access to host machine
- Consider firewall rules to isolate containers
- Regular backup testing

## Contributing

Issues and pull requests welcome. This is infrastructure for real use, so practical improvements are valued.

## License

MIT
