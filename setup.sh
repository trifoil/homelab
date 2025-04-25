#!/bin/bash

BLUE='\e[38;5;33m'
RED='\e[38;5;196m'
NC='\033[0m' # No Color

clear

# Function to display the menu
display_menu() {
    echo ""
    echo "|-----------------------------------------------------------------------|"
    echo -e "|                   ${BLUE}Welcome to the setup assistant ${NC}                     |"
    echo "|                Please select the tool you want to use                 |"
    echo "|-----------------------------------------------------------------------|"
    echo -e "|  0. Setup Docker                                             ${RED}REQUIRED ${NC}|"
    echo "|  1. Setup Portainer                                                   |"
    echo "|  2. Setup Traefik                                                     |"
    echo "|  3. Setup NGINX Proxy Manager                                         |"
    echo "|  4. Setup Pi-hole                                                     |"
    echo "|  5. Setup WireGuard VPN                                               |"
    echo "|  6. Setup Obfuscated WireGuard VPN                                    |"
    echo "|  7. Setup HomeAssistant                                               |"
    echo "|  8. Setup Nextcloud AIO                                               |"
    echo "|  9. Setup GitBucket                                                   |"
    echo "| 10. Setup Matrix Server                                               |"
    echo "| 11. Setup Alternative Monitoring Tool (e.g., Prometheus, Grafana)     |"
    echo "| 12. Setup Vaultwarden                                                 |"
    echo "| 13. Setup FileBrowser                                                 |"
    echo "| 14. Setup Streaming (deluge + jellyfin)                               |"
    echo "| 15. Setup Vanilla JS Website                                          |"
    echo "| 16. Setup DDNS Updater                                                |"
    echo "| 17. Setup SOTF (sons of the forest) Server                            |"
    echo "| 18. Setup Dead Man's Switch                                           |"
    echo "|-----------------------------------------------------------------------|"
    echo "|  q. Exit                                                              |"
    echo "|-----------------------------------------------------------------------|"
    echo ""
}

setup_docker(){
    sh scripts/setup/docker_setup/docker_setup.sh
}

setup_npm(){
    sh scripts/setup/npm_setup/npm_setup.sh
}

setup_portainer(){
    sh scripts/setup/portainer_setup/portainer_setup.sh
}

setup_traefik(){
    sh scripts/setup/traefik_setup/traefik_setup.sh
}

setup_pihole(){
    sh scripts/setup/pihole_setup/pihole_setup.sh
}

setup_wireguard_vpn(){
    sh scripts/setup/wireguard_vpn_setup/wireguard_vpn_setup.sh
}

setup_obfuscated_wireguard_vpn(){
    sh scripts/setup/obfuscated_wireguard_vpn_setup/obfuscated_wireguard_vpn_setup.sh
}

setup_homeassistant(){
    sh scripts/setup/homeassistant_setup/homeassistant_setup.sh
}

setup_nextcloud_aio(){
    sh scripts/setup/nextcloud_aio_setup/nextcloud_aio_setup.sh
}

setup_gitbucket(){
    sh scripts/setup/gitbucket_setup/gitbucket_setup.sh
}

setup_matrix(){
    sh scripts/setup/matrix_setup/matrix_setup.sh
}

setup_monitoring(){
    sh scripts/setup/monitoring_setup/monitoring_setup.sh
}

setup_vaultwarden(){
    sh scripts/setup/vaultwarden_setup/vaultwarden_setup.sh
}

setup_filebrowser(){
    sh scripts/setup/filebrowser_setup/filebrowser_setup.sh
}

setup_streaming(){
    sh scripts/setup/streaming_setup/streaming_setup.sh
}

setup_vanilla_js_website(){
    sh scripts/setup/js_website_setup/js_website_setup.sh
}

setup_ddns_updater(){
    sh scripts/setup/ddns_updater_setup/ddns_updater_setup.sh
}

setup_sotf(){
    sh scripts/setup/sotf_server_setup/sotf_server_setup.sh
}

setup_dead_man_switch(){
    sh scripts/setup/dead_man_switch_setup/dead_man_switch_setup.sh
}

main() {
    while true; do
        display_menu
        read -p "Enter your choice: " choice
        case $choice in
            0) setup_docker ;;
            1) setup_portainer ;;
            2) setup_traefik ;;
            3) setup_npm ;;
            4) setup_pihole ;;
            5) setup_wireguard_vpn ;;
            6) setup_obfuscated_wireguard_vpn ;;
            7) setup_homeassistant ;;
            8) setup_nextcloud_aio ;;
            9) setup_gitbucket ;;
            10) setup_matrix ;;
            11) setup_monitoring ;;
            12) setup_vaultwarden ;;
            13) setup_filebrowser ;;
            14) setup_streaming ;;
            15) setup_vanilla_js_website ;;
            16) setup_ddns_updater ;;
            17) setup_sotf ;;
            18) setup_dead_man_switch ;;
            q) clear && echo "Bye loser!" && exit;;
            *) clear && echo "Invalid choice. Please enter a valid option." ;;
        esac
        clear
    done
}

main
