# ✇ Fedora-server 

Homelab install tailored for personal use, under fedora, but most probably compatible with a lot of distros

## Tools

[![DDNS Updater](https://img.shields.io/badge/DDNS_Updater-000000?style=for-the-badge&logo=ddns&logoColor=white)](https://en.wikipedia.org/wiki/Dynamic_DNS)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Filebrowser](https://img.shields.io/badge/Filebrowser-000000?style=for-the-badge&logo=filebrowser&logoColor=white)](https://filebrowser.org/)
[![GitBucket](https://img.shields.io/badge/GitBucket-000000?style=for-the-badge&logo=gitbucket&logoColor=white)](https://gitbucket.github.io/)
[![Home Assistant](https://img.shields.io/badge/Home_Assistant-41BDF5?style=for-the-badge&logo=home-assistant&logoColor=white)](https://www.home-assistant.io/)
[![npm](https://img.shields.io/badge/npm-CB3837?style=for-the-badge&logo=npm&logoColor=white)](https://www.npmjs.com/)
[![Matrix Protocol](https://img.shields.io/badge/Matrix_Protocol-000000?style=for-the-badge&logo=matrix&logoColor=white)](https://matrix.org/)
[![Nextcloud](https://img.shields.io/badge/Nextcloud-0082C9?style=for-the-badge&logo=nextcloud&logoColor=white)](https://nextcloud.com/)
[![Nginx Proxy Manager](https://img.shields.io/badge/Nginx_Proxy_Manager-009639?style=for-the-badge&logo=nginx&logoColor=white)](https://nginxproxymanager.com/)
[![WireGuard](https://img.shields.io/badge/WireGuard-88171A?style=for-the-badge&logo=wireguard&logoColor=white)](https://www.wireguard.com/)
[![WS Tunnel](https://img.shields.io/badge/WS_Tunnel-000000?style=for-the-badge&logo=ws-tunnel&logoColor=white)](https://github.com/erebe/wstunnel)
[![Portainer](https://img.shields.io/badge/Portainer-13BEF9?style=for-the-badge&logo=portainer&logoColor=white)](https://www.portainer.io/)
[![Jellyfin](https://img.shields.io/badge/Jellyfin-00A4DC?style=for-the-badge&logo=jellyfin&logoColor=white)](https://jellyfin.org/)
[![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=for-the-badge&logo=traefik&logoColor=white)](https://traefik.io/)
[![Uptime Kuma](https://img.shields.io/badge/Uptime_Kuma-000000?style=for-the-badge&logo=uptime-kuma&logoColor=white)](https://github.com/louislam/uptime-kuma)

## Quick start - server

```sh
rm -rf homelab
sudo dnf install git -y
git clone https://github.com/trifoil/homelab.git
cd homelab
sudo sh main_server.sh
cd ..
clear
```

## Quick start - fedora client

```sh
rm -rf Fedora-server
sudo dnf install git -y
git clone https://github.com/trifoil/Fedora-server.git
cd Fedora-server
sudo sh main_client.sh
cd ..
clear
```

## What's included :

Installed from the script and ```required``` for the other services : 

* Docker (install it through this script, that follows the official way)

Admin services :

- [x] Portainer
- [x] Nginx Proxy Manager
- [x] DDNS updater
- [ ] Uptime-kuma
- [x] FileBrowser
- [ ] OpenVPN

User services :

- [x] Nextcloud AIO
- [x] Jellyfin
- [x] Deluge
- [ ] Gitbucket

## Sources

* https://github.com/louislam/uptime-kuma
* https://github.com/pgollor/gitbucket-docker/tree/master
* https://github.com/qdm12/ddns-updater/blob/master/docker-compose.yml
* https://github.com/element-hq/synapse/blob/develop/contrib/docker/docker-compose.yml
* https://github.com/OpenVPN/as-docker
* https://github.com/pgollor/gitbucket-docker/blob/master/docker-compose.yml
* https://ocserv.openconnect-vpn.net/packages

