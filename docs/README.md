# Homelab Setup

This repository contains all the scripts and configuration files needed to set up a Docker-based homelab environment.

## Directory Structure

- **config/**: Configuration files and environment variables.
- **services/**: Docker Compose files for each service.
- **scripts/**: Shell scripts for managing the homelab.
- **docs/**: Documentation and architecture diagram.
- **Makefile**: Makefile for automating tasks.
- **.gitignore**: Git ignore file.

## Services

This homelab setup includes the following services:

- Authentik
- Cloudflare Tunnel
- Code-Server
- DIUN
- Gotify
- Grafana Monitoring
- Homepage
- Immich
- Jellyfin
- Pihole
- Portainer
- Torrent-VPN
- Traefik
- UptimeKuma

## Usage

To set up the environment and configure startup tasks:

```
make install
```

To start all services:

```
make start
```

To deploy Docker services:

```
make deploy
```

To stop all services:

```
make stop
```

To configure macvlan:

```
make macvlan
```

To configure DNS:

```
make dns
```

To uninstall the setup:

```
make uninstall
```

