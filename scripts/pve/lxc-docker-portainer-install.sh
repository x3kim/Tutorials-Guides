#!/bin/bash

# Stoppt das Skript sofort, wenn ein Befehl fehlschlägt
set -e

# --- Standardmodus: wird jetzt interaktiv gesetzt ---
VERBOSE_MODE=false # Standardwert, falls Abfrage übersprungen wird

# --- Farben und Formatierungen ---
C_OFF='\033[0m'       # Text Reset
C_RED='\033[0;31m'          # Red
C_GREEN='\033[0;32m'        # Green
C_YELLOW='\033[0;33m'       # Yellow
C_BLUE='\033[0;34m'         # Blue
C_MAGENTA='\033[0;35m'      # Magenta
C_CYAN='\033[0;36m'         # Cyan
C_WHITE='\033[0;37m'        # White
C_BOLD='\033[1m'            # Bold
C_DIM='\033[2m'             # Dim
C_UNDERLINE='\033[4m'       # Underline

# --- Emojis ---
E_ROCKET="🚀"
E_GEAR="⚙️"
E_CHECK="✅"
E_WARN="⚠️"
E_INFO="ℹ️"
E_PROMPT="💬"
E_PARTY="🎉"
E_BOX="📦"
E_KEY="🔑"
E_LIST="📋"
E_LINK="🔗"
E_PENGUIN="🐧"
E_SHIP="🚢"
E_EYES="👀"

# --- Hilfsfunktionen für die Ausgabe ---
print_header() {
    echo -e "\n${C_BLUE}${C_BOLD}=========================================================${C_OFF}"
    echo -e "${C_BLUE}${C_BOLD}      $1      ${C_OFF}"
    echo -e "${C_BLUE}${C_BOLD}=========================================================${C_OFF}\n"
}

print_phase() {
    echo -e "\n${C_MAGENTA}${C_BOLD}>>> [PHASE $1] $2 <<<\n${C_OFF}"
}

print_step() {
    echo -e "${C_CYAN}${E_GEAR}  $1...${C_OFF}"
}

print_success() {
    echo -e "${C_GREEN}${E_CHECK}  $1${C_OFF}"
}

print_warning() {
    echo -e "${C_YELLOW}${E_WARN}  $1${C_OFF}"
}

print_info() {
    echo -e "${C_WHITE}${E_INFO}  $1${C_OFF}"
}

prompt_user_select() {
    local prompt_message="$1"
    local var_name="$2"
    local options_text="$3" # z.B. "(y/N)"
    read -r -p "$(echo -e "${C_YELLOW}${E_PROMPT}  ${prompt_message} ${options_text}: ${C_OFF}")" "$var_name"
}

# --- Funktion zum Ausführen von Befehlen (berücksichtigt Verbose-Modus) ---
run_command() {
    if [ "$VERBOSE_MODE" = true ]; then
        echo -e "${C_DIM}↪ Executing: $*${C_OFF}"
        "$@"
    else
        "$@" >/dev/null 2>&1
    fi
    return $?
}

# --- Funktion zum Ermitteln der primären IP-Adresse ---
get_primary_ip() {
    # Versucht, die IP von 'ip route get 1.1.1.1' (verlässlicher)
    # oder als Fallback von 'hostname -I' (kann mehrere IPs liefern)
    local ip_address
    ip_address=$(ip route get 1.1.1.1 2>/dev/null | awk -F"src " 'NR==1{print $2}' | awk '{print $1}')
    if [ -z "$ip_address" ]; then
        ip_address=$(hostname -I | awk '{print $1}') # Nimmt die erste IP, falls mehrere
    fi

    if [ -n "$ip_address" ]; then
        echo "$ip_address"
    else
        # Hier wird der spezielle Rückgabewert gesetzt, wenn keine IP gefunden wurde
        echo "NO_IP_FOUND"
    fi
}

# === SKRIPTSTART ===
clear
print_header "${E_PENGUIN} Docker & ${E_SHIP} Portainer Installation Assistant ${E_ROCKET}"

# Interaktive Auswahl für Verbose-Modus
prompt_user_select "Do you want to enable detailed output mode (Verbose)?" VERBOSE_CHOICE "(y/N)"
if [[ "$VERBOSE_CHOICE" =~ ^[yY](es|ES)?$ ]]; then
    VERBOSE_MODE=true
    print_info "${E_EYES} Verbose mode is ${C_GREEN}ACTIVE${C_OFF}. Detailed output will be displayed."
else
    VERBOSE_MODE=false
    print_info "Standard mode (compact output)."
fi
echo # Leerzeile

# Prüfen, ob das Skript mit Root-Rechten ausgeführt wird
SUDO_CMD=""
CURRENT_USER_IS_ROOT=false
if [ "$(id -u)" -eq 0 ]; then
  print_info "Script is running as ${C_BOLD}root${C_OFF}."
  CURRENT_USER_IS_ROOT=true
else
  print_info "Script is not running as root."
  if ! command -v sudo &> /dev/null; then
    echo -e "${C_RED}${C_BOLD}ERROR: sudo could not be found. Please install sudo or run the script as root.${C_OFF}"
    exit 1
  fi
  SUDO_CMD="sudo"
  print_info "Using '${C_BOLD}sudo${C_OFF}' for privileged operations."
fi

# --- Docker Installation ---
print_phase "1/2" "${E_PENGUIN} Installing Docker"

print_step "Updating system package lists and installing dependencies"
run_command $SUDO_CMD apt-get update
run_command $SUDO_CMD apt-get install -y ca-certificates curl
print_success "System prepared."

print_step "Adding Docker GPG Key"
run_command $SUDO_CMD install -m 0755 -d /etc/apt/keyrings
run_command $SUDO_CMD rm -f /etc/apt/keyrings/docker.asc
run_command $SUDO_CMD curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
run_command $SUDO_CMD chmod a+r /etc/apt/keyrings/docker.asc
print_success "Docker GPG Key ${E_KEY} added."

print_step "Adding Docker repository to Apt sources ${E_LIST}"
if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    if [ -z "$VERSION_CODENAME" ]; then
        echo -e "${C_RED}${C_BOLD}Error: VERSION_CODENAME could not be determined from /etc/os-release.${C_OFF}"
        exit 1
    fi
else
    echo -e "${C_RED}${C_BOLD}Error: /etc/os-release not found. This script is intended for Debian-based systems.${C_OFF}"
    exit 1
fi

# Im Verbose-Modus zeigen wir den Inhalt, der in die Datei geschrieben wird
if [ "$VERBOSE_MODE" = true ]; then
    echo -e "${C_DIM}↪ Writing to /etc/apt/sources.list.d/docker.list:${C_OFF}"
    echo -e "${C_DIM}  deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \"$VERSION_CODENAME\" stable${C_OFF}"
fi
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  \"$VERSION_CODENAME\" stable" | \
  $SUDO_CMD tee /etc/apt/sources.list.d/docker.list > /dev/null
run_command $SUDO_CMD apt-get update
print_success "Docker repository added and package lists updated."

print_step "Installing Docker packages ${E_BOX}"
run_command $SUDO_CMD apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
print_success "Docker CE, CLI, Containerd and plugins successfully installed!"

# Optional: Benutzer zur Docker-Gruppe hinzufügen
target_user_for_docker_group=""
if [ "$CURRENT_USER_IS_ROOT" = true ]; then
    prompt_user_select "You are logged in as root. Do you want to add a regular user to the Docker group?" user_to_add_choice "(Enter username or 'N' to skip)"
    if [[ ! "$user_to_add_choice" =~ ^[nN](o|O)?$ && -n "$user_to_add_choice" ]]; then
        if id "$user_to_add_choice" &>/dev/null; then
            target_user_for_docker_group="$user_to_add_choice"
        else
            print_warning "User '$user_to_add_choice' not found. Skipping."
        fi
    fi
else
    if [ -n "$SUDO_USER" ]; then
        target_user_for_docker_group="$SUDO_USER"
    else
        target_user_for_docker_group="$USER"
    fi
fi

if [ -n "$target_user_for_docker_group" ]; then
    if ! groups "$target_user_for_docker_group" | grep -q '\bdocker\b'; then
        print_step "Adding user '${C_BOLD}$target_user_for_docker_group${C_OFF}' to the Docker group"
        run_command $SUDO_CMD usermod -aG docker "$target_user_for_docker_group"
        print_success "User '${C_BOLD}$target_user_for_docker_group${C_OFF}' added to the Docker group."
        print_info "For the changes to take effect, '${C_BOLD}$target_user_for_docker_group${C_OFF}' must log out and log back in, or run 'newgrp docker'."
    else
        print_info "User '${C_BOLD}$target_user_for_docker_group${C_OFF}' is already in the Docker group."
    fi
else
    print_info "No user specified or skipped: Step to add user to Docker group will not be executed."
    if [ "$CURRENT_USER_IS_ROOT" = true ]; then
        print_info "As root, this is not necessary for direct Docker usage."
    fi
fi

print_success "${E_PENGUIN} Docker installation completed!"

# --- Portainer Installation ---
print_phase "2/2" "${E_SHIP} Installing Portainer"

print_step "Creating Portainer data volume 'portainer_data'"
if $SUDO_CMD docker volume inspect portainer_data >/dev/null 2>&1; then
    print_info "Docker volume 'portainer_data' already exists."
else
    if [ "$VERBOSE_MODE" = true ]; then
        $SUDO_CMD docker volume create portainer_data
    else
        $SUDO_CMD docker volume create portainer_data >/dev/null
    fi
    print_success "Docker volume 'portainer_data' created."
fi

print_step "Starting/updating Portainer server container"
container_name="portainer"
if $SUDO_CMD docker ps -a --format '{{.Names}}' | grep -Eq "^${container_name}$"; then
    print_warning "A container named '${C_BOLD}${container_name}${C_OFF}' already exists."
    prompt_user_select "Do you want to stop and remove the existing Portainer container to recreate it?" confirm_remove "(y/N)"
    if [[ "$confirm_remove" =~ ^[yY](es|ES)?$ ]]; then
        print_step "Stopping and removing existing Portainer container..."
        run_command $SUDO_CMD docker stop "$container_name"
        run_command $SUDO_CMD docker rm "$container_name"
        print_success "Existing Portainer container removed."
    else
        print_warning "Portainer installation aborted as a container with the same name exists and was not removed."
        exit 1
    fi
fi

print_step "Starting Portainer server container (portainer/portainer-ce:lts)"
if [ "$VERBOSE_MODE" = true ]; then
    $SUDO_CMD docker run -d \
        -p 8000:8000 \
        -p 9443:9443 \
        --name "$container_name" \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:lts
else
    $SUDO_CMD docker run -d \
        -p 8000:8000 \
        -p 9443:9443 \
        --name "$container_name" \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:lts >/dev/null
fi
print_success "Portainer server container successfully started!"

print_success "${E_SHIP} Portainer installation completed!"

# --- Abschlussmeldung ---
SERVER_IP=$(get_primary_ip) # IP-Adresse ermitteln

echo -e "\n${C_GREEN}${C_BOLD}=========================================================${C_OFF}"
echo -e "${C_GREEN}${C_BOLD}      ${E_PARTY} Installation successfully completed! ${E_PARTY}      ${C_OFF}"
echo -e "${C_GREEN}${C_BOLD}=========================================================${C_OFF}\n"
echo -e "${C_WHITE}Portainer should now be accessible at:${C_OFF}"

if [ "$SERVER_IP" == "NO_IP_FOUND" ]; then
    echo -e "  ${C_YELLOW}${E_WARN} Could not automatically determine server IP address. ${E_PROMPT}${C_OFF}"
    echo -e "  ${C_WHITE}Please replace ${C_BOLD}<YOUR_SERVER_IP_OR_HOSTNAME>${C_OFF} with your actual server IP or hostname:${C_OFF}"
    echo -e "  ${C_UNDERLINE}${C_BLUE}https://<YOUR_SERVER_IP_OR_HOSTNAME>:9443${C_OFF} ${E_LINK}"
    echo -e "  (Copy: https://<YOUR_SERVER_IP_OR_HOSTNAME>:9443 )"
else
    # Anklickbarer Link (funktioniert in vielen modernen Terminals)
    echo -e "  ${C_UNDERLINE}${C_BLUE}https://$(echo "$SERVER_IP" | sed 's/\([.]\)/\\\1/g'):9443${C_OFF} ${E_LINK}"
    echo -e "  (If the link is not clickable, copy: https://${SERVER_IP}:9443 )"
fi

echo -e "\n${C_WHITE}On first access, you will need to create an administrator account for Portainer.${C_OFF}"

if [ -n "$target_user_for_docker_group" ] && [ "$target_user_for_docker_group" != "root" ] && [ "$CURRENT_USER_IS_ROOT" = false ]; then
  echo -e "\n${C_YELLOW}${E_WARN}  IMPORTANT: To run Docker commands as user '${C_BOLD}$target_user_for_docker_group${C_OFF}' without 'sudo',"
  echo -e "  they must ${C_BOLD}log out and log back in${C_OFF} or run '${C_BOLD}newgrp docker${C_OFF}' in a new shell.${C_OFF}"
elif [ -n "$target_user_for_docker_group" ] && [ "$target_user_for_docker_group" != "root" ] && [ "$CURRENT_USER_IS_ROOT" = true ]; then
  echo -e "\n${C_YELLOW}${E_INFO}  NOTE: User '${C_BOLD}$target_user_for_docker_group${C_OFF}' has been added to the Docker group."
  echo -e "  For them to use Docker without 'sudo', they must ${C_BOLD}log out and log back in${C_OFF} or run '${C_BOLD}newgrp docker${C_OFF}'."
fi
echo -e "\n${C_CYAN}Enjoy Docker and Portainer! ${E_ROCKET}${C_OFF}\n"

exit 0
