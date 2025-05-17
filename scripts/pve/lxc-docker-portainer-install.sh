#!/bin/bash

# Stoppt das Skript sofort, wenn ein Befehl fehlschlägt
set -e

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

# --- Emojis (optional, prüfen Sie die Terminal-Kompatibilität) ---
E_ROCKET="🚀"
E_GEAR="⚙️"
E_CHECK="✅"
E_WARN="⚠️"
E_INFO="ℹ️"
E_PROMPT="🤔"
E_PARTY="🎉"
E_BOX="📦"
E_KEY="🔑"
E_LIST="📋"
E_LINK="🔗"
E_PENGUIN="🐧" # Docker ist ein Wal, aber Linux ist ein Pinguin :)
E_SHIP="🚢"   # Für Portainer

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

prompt_user() {
    local prompt_message="$1"
    local var_name="$2"
    read -r -p "$(echo -e "${C_YELLOW}${E_PROMPT}  ${prompt_message}${C_OFF}")" "$var_name"
}

# === SKRIPTSTART ===
clear # Bildschirm zu Beginn säubern (optional)
print_header "${E_PENGUIN} Docker & ${E_SHIP} Portainer Installationszauberer ${E_ROCKET}"

# Prüfen, ob das Skript mit Root-Rechten ausgeführt wird
SUDO_CMD=""
CURRENT_USER_IS_ROOT=false
if [ "$(id -u)" -eq 0 ]; then
  print_info "Skript wird als ${C_BOLD}root${C_OFF} ausgeführt."
  CURRENT_USER_IS_ROOT=true
else
  print_info "Skript wird nicht als root ausgeführt."
  if ! command -v sudo &> /dev/null; then
    echo -e "${C_RED}${C_BOLD}FEHLER: sudo konnte nicht gefunden werden. Bitte installieren Sie sudo oder führen Sie das Skript als root aus.${C_OFF}"
    exit 1
  fi
  SUDO_CMD="sudo"
  print_info "Für privilegierte Operationen wird '${C_BOLD}sudo${C_OFF}' verwendet."
fi

# --- Docker Installation ---
print_phase "1/2" "${E_PENGUIN} Docker wird installiert"

print_step "System-Paketlisten aktualisieren und Abhängigkeiten installieren"
$SUDO_CMD apt-get update >/dev/null 2>&1 # Ausgabe unterdrücken für mehr Übersicht
$SUDO_CMD apt-get install -y ca-certificates curl >/dev/null 2>&1
print_success "System vorbereitet."

print_step "Docker GPG Key hinzufügen"
$SUDO_CMD install -m 0755 -d /etc/apt/keyrings
$SUDO_CMD rm -f /etc/apt/keyrings/docker.asc # Ggf. alten Key entfernen
$SUDO_CMD curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
$SUDO_CMD chmod a+r /etc/apt/keyrings/docker.asc
print_success "Docker GPG Key ${E_KEY} hinzugefügt."

print_step "Docker Repository zu Apt Quellen ${E_LIST} hinzufügen"
if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    if [ -z "$VERSION_CODENAME" ]; then
        echo -e "${C_RED}${C_BOLD}Fehler: VERSION_CODENAME konnte nicht aus /etc/os-release ermittelt werden.${C_OFF}"
        exit 1
    fi
else
    echo -e "${C_RED}${C_BOLD}Fehler: /etc/os-release nicht gefunden. Dieses Skript ist für Debian-basierte Systeme gedacht.${C_OFF}"
    exit 1
fi
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  "$VERSION_CODENAME" stable" | \
  $SUDO_CMD tee /etc/apt/sources.list.d/docker.list > /dev/null
$SUDO_CMD apt-get update >/dev/null 2>&1
print_success "Docker Repository hinzugefügt und Paketlisten aktualisiert."

print_step "Docker Pakete ${E_BOX} installieren"
$SUDO_CMD apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null 2>&1
print_success "Docker CE, CLI, Containerd und Plugins erfolgreich installiert!"

# Optional: Benutzer zur Docker-Gruppe hinzufügen
target_user_for_docker_group=""
if [ "$CURRENT_USER_IS_ROOT" = true ]; then
    prompt_user "Sie sind als root angemeldet. Möchten Sie einen regulären Benutzer zur Docker-Gruppe hinzufügen? (Benutzername eingeben oder leer lassen zum Überspringen): " user_to_add
    if [ -n "$user_to_add" ]; then
        if id "$user_to_add" &>/dev/null; then
            target_user_for_docker_group="$user_to_add"
        else
            print_warning "Benutzer '$user_to_add' nicht gefunden. Überspringe."
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
        print_step "Benutzer '${C_BOLD}$target_user_for_docker_group${C_OFF}' zur Docker-Gruppe hinzufügen"
        $SUDO_CMD usermod -aG docker "$target_user_for_docker_group"
        print_success "Benutzer '${C_BOLD}$target_user_for_docker_group${C_OFF}' zur Docker-Gruppe hinzugefügt."
        print_info "Damit die Änderungen wirksam werden, muss sich '${C_BOLD}$target_user_for_docker_group${C_OFF}' ab- und wieder anmelden oder 'newgrp docker' ausführen."
    else
        print_info "Benutzer '${C_BOLD}$target_user_for_docker_group${C_OFF}' ist bereits in der Docker-Gruppe."
    fi
else
    print_info "Kein Benutzer spezifiziert: Schritt zum Hinzufügen zur Docker-Gruppe übersprungen."
    if [ "$CURRENT_USER_IS_ROOT" = true ]; then
        print_info "Als root ist dies nicht notwendig für die direkte Nutzung von Docker."
    fi
fi

print_success "${E_PENGUIN} Docker Installation abgeschlossen!"

# --- Portainer Installation ---
print_phase "2/2" "${E_SHIP} Portainer wird installiert"

print_step "Portainer Datenvolume 'portainer_data' erstellen"
if $SUDO_CMD docker volume inspect portainer_data >/dev/null 2>&1; then
    print_info "Docker Volume 'portainer_data' existiert bereits."
else
    $SUDO_CMD docker volume create portainer_data >/dev/null
    print_success "Docker Volume 'portainer_data' erstellt."
fi

print_step "Portainer Server Container starten/aktualisieren"
container_name="portainer"
if $SUDO_CMD docker ps -a --format '{{.Names}}' | grep -Eq "^${container_name}$"; then
    print_warning "Ein Container namens '${C_BOLD}${container_name}${C_OFF}' existiert bereits."
    prompt_user "Möchten Sie den existierenden Portainer Container stoppen und entfernen, um ihn neu zu erstellen? (j/N): " confirm_remove
    if [[ "$confirm_remove" =~ ^[jJ](a|A)?$ ]]; then
        print_step "Stoppe und entferne existierenden Portainer Container..."
        $SUDO_CMD docker stop "$container_name" >/dev/null && $SUDO_CMD docker rm "$container_name" >/dev/null
        print_success "Existierender Portainer Container entfernt."
    else
        print_warning "Portainer Installation abgebrochen, da ein gleichnamiger Container existiert und nicht entfernt wurde."
        exit 1
    fi
fi

print_step "Portainer Server Container (portainer/portainer-ce:lts) wird gestartet"
$SUDO_CMD docker run -d \
    -p 8000:8000 \
    -p 9443:9443 \
    --name "$container_name" \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:lts >/dev/null
print_success "Portainer Server Container erfolgreich gestartet!"

print_success "${E_SHIP} Portainer Installation abgeschlossen!"

# --- Abschlussmeldung ---
echo -e "\n${C_GREEN}${C_BOLD}=========================================================${C_OFF}"
echo -e "${C_GREEN}${C_BOLD}      ${E_PARTY} Installation erfolgreich abgeschlossen! ${E_PARTY}      ${C_OFF}"
echo -e "${C_GREEN}${C_BOLD}=========================================================${C_OFF}\n"
echo -e "${C_WHITE}Portainer sollte jetzt erreichbar sein unter:${C_OFF}"
echo -e "  ${C_UNDERLINE}${C_BLUE}https://<IHRE_SERVER_IP_ODER_HOSTNAME>:9443${C_OFF} ${E_LINK}"
echo -e "\n${C_WHITE}Beim ersten Zugriff müssen Sie ein Administratorkonto für Portainer erstellen.${C_OFF}"

if [ -n "$target_user_for_docker_group" ] && [ "$target_user_for_docker_group" != "root" ] && [ "$CURRENT_USER_IS_ROOT" = false ]; then
  echo -e "\n${C_YELLOW}${E_WARN}  WICHTIG: Um Docker-Befehle als Benutzer '${C_BOLD}$target_user_for_docker_group${C_OFF}' ohne 'sudo' auszuführen,"
  echo -e "  muss sich dieser ${C_BOLD}abmelden und erneut anmelden${C_OFF} oder '${C_BOLD}newgrp docker${C_OFF}' in einer neuen Shell ausführen.${C_OFF}"
elif [ -n "$target_user_for_docker_group" ] && [ "$target_user_for_docker_group" != "root" ] && [ "$CURRENT_USER_IS_ROOT" = true ]; then
  echo -e "\n${C_YELLOW}${E_WARN}  HINWEIS: Der Benutzer '${C_BOLD}$target_user_for_docker_group${C_OFF}' wurde zur Docker-Gruppe hinzugefügt."
  echo -e "  Damit dieser Docker ohne 'sudo' nutzen kann, muss er sich ${C_BOLD}abmelden und erneut anmelden${C_OFF} oder '${C_BOLD}newgrp docker${C_OFF}' ausführen.${C_OFF}"
fi
echo -e "\n${C_CYAN}Viel Spaß mit Docker und Portainer! ${E_ROCKET}${C_OFF}\n"

exit 0
