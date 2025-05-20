#!/bin/bash

# Stops the script immediately if a command fails
set -e

# --- Default settings ---
VERBOSE_MODE=false
INSTALL_METHOD="general" # Default to general, will be prompted
SUPABASE_CODE_DIR="supabase_src_temp" # Temporary directory for git clone
PROJECT_DIR_NAME="supabase-project" # Name of the final project directory
ACCESS_TYPE="local" # Default access type, will be prompted

# --- Colors and Formatting ---
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
E_CLOUD="☁️" # For Supabase/Cloud
E_DB="💾"    # For Database
E_SHIELD="🛡️" # For Security
E_UPDATE="🔄" # For updates
E_CLEAN="🧹"  # For cleanup tasks
E_EYES="👀"   # For verbose mode active
E_NETWORK="🌐" # For network/remote access

# --- Helper functions for output ---
print_header() {
    echo -e "\n${C_BLUE}${C_BOLD}=========================================================${C_OFF}"
    echo -e "${C_BLUE}${C_BOLD}      $1      ${C_OFF}"
    echo -e "${C_BLUE}${C_BOLD}=========================================================${C_OFF}\n"
}

print_phase() {
    echo -e "\n${C_MAGENTA}${C_BOLD}>>> [PHASE $1/$TOTAL_PHASES] $2 <<<\n${C_OFF}"
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
    local options_text="$3" # e.g., "(y/N)" or "[default: general]"
    read -r -p "$(echo -e "${C_YELLOW}${E_PROMPT}  ${prompt_message} ${options_text}: ${C_OFF}")" "$var_name"
}

# --- Function to execute commands (respects Verbose mode) ---
run_command() {
    if [ "$VERBOSE_MODE" = true ]; then
        echo -e "${C_DIM}↪ Executing: $*${C_OFF}"
        "$@" # Executes the command and shows its full output
    else
        "$@" >/dev/null 2>&1 # Executes the command and suppresses its output
    fi
    return $? # Returns the exit code of the last command
}

# --- Function to execute commands and show output (even if not verbose) ---
run_command_show_output() {
    if [ "$VERBOSE_MODE" = true ]; then
        echo -e "${C_DIM}↪ Executing: $*${C_OFF}"
    fi
    "$@" # Executes the command and shows its full output
    return $?
}


# --- Function to determine the primary IP address ---
get_primary_ip() {
    local ip_address
    ip_address=$(ip route get 1.1.1.1 2>/dev/null | awk -F"src " 'NR==1{print $2}' | awk '{print $1}')
    if [ -z "$ip_address" ]; then
        ip_address=$(hostname -I | awk '{print $1}')
    fi

    if [ -n "$ip_address" ]; then
        echo "$ip_address"
    else
        echo "NO_IP_FOUND"
    fi
}

# === SCRIPT START ===
clear
print_header "${E_CLOUD} Supabase Self-Hosting Installation Assistant ${E_ROCKET}"

# Interactive selection for Verbose mode
prompt_user_select "Enable detailed output (Verbose Mode)?" VERBOSE_CHOICE "(y/N)"
if [[ "$VERBOSE_CHOICE" =~ ^[yY](es|ES)?$ ]]; then
    VERBOSE_MODE=true
    print_info "${E_EYES} Verbose mode is ${C_GREEN}ACTIVE${C_OFF}. Detailed output will be displayed."
else
    VERBOSE_MODE=false
    print_info "Standard mode (compact output)."
fi
echo

# Interactive selection for Installation Method
print_info "Supabase offers two main ways to get its Docker files:"
print_info "  1. ${C_BOLD}General:${C_OFF} Clones only the necessary files (faster, recommended for most)."
print_info "  2. ${C_BOLD}Advanced:${C_OFF} Clones the full repository then uses sparse-checkout (more complex)."
prompt_user_select "Choose installation method (1 for General, 2 for Advanced)" METHOD_CHOICE "[default: 1]"

if [[ "$METHOD_CHOICE" == "2" ]]; then
    INSTALL_METHOD="advanced"
    print_info "Using ${C_BOLD}Advanced${C_OFF} installation method."
else
    INSTALL_METHOD="general" # Default or if '1' or invalid is entered
    print_info "Using ${C_BOLD}General${C_OFF} installation method."
fi
echo

# Interactive selection for Access Type (Localhost vs Remote)
print_info "${E_NETWORK} Supabase Access Configuration:"
print_info "  This determines how URLs (SITE_URL, API_EXTERNAL_URL, SUPABASE_PUBLIC_URL) are set in the .env file."
print_info "  1. ${C_BOLD}Local:${C_OFF} URLs will be set to 'localhost'. Suitable if accessing Supabase only from the same machine where Docker is running."
print_info "  2. ${C_BOLD}Remote:${C_OFF} URLs will be set to this server's IP or a custom domain. Necessary if accessing Supabase from other devices on your network or the internet."
prompt_user_select "Configure Supabase for Local or Remote access? (1 for Local, 2 for Remote)" ACCESS_TYPE_CHOICE "[default: 1]"

if [[ "$ACCESS_TYPE_CHOICE" == "2" ]]; then
    ACCESS_TYPE="remote"
    print_info "Configuring for ${C_BOLD}Remote Access${C_OFF}. URLs will be customized."
else
    ACCESS_TYPE="local" # Default or if '1' or invalid is entered
    print_info "Configuring for ${C_BOLD}Local Access${C_OFF}. URLs will use 'localhost'."
fi
echo


# --- Calculate total phases ---
CURRENT_PHASE_NUM=0
TOTAL_PHASES=4 # Prep, Get Code, Configure & Run, Post-Install

# Check if the script is running with root privileges
SUDO_CMD=""
if [ "$(id -u)" -ne 0 ]; then
  if ! command -v sudo &> /dev/null; then
    echo -e "${C_RED}${C_BOLD}ERROR: sudo could not be found. Please install sudo or run the script as root.${C_OFF}"
    exit 1
  fi
  SUDO_CMD="sudo"
  print_info "Using '${C_BOLD}sudo${C_OFF}' for privileged operations."
else
  print_info "Script is running as ${C_BOLD}root${C_OFF}."
fi

# --- Phase 1: System Preparation & Prerequisite Checks ---
CURRENT_PHASE_NUM=$((CURRENT_PHASE_NUM + 1))
print_phase "$CURRENT_PHASE_NUM" "${E_UPDATE} System Preparation & Prerequisite Checks"

print_step "Updating package lists"
run_command $SUDO_CMD apt-get update
print_success "Package lists updated."

print_step "Ensuring 'git' is installed"
if ! command -v git &> /dev/null; then
    run_command $SUDO_CMD apt-get install -y git
    print_success "'git' installed."
else
    print_info "'git' is already installed."
fi

print_step "Checking for Docker and Docker Compose"
if ! command -v docker &> /dev/null; then
    print_warning "Docker command not found. Please install Docker before running this script."
    print_info "You can use a script like https://get.docker.com or your distribution's package manager."
    exit 1
fi
if ! $SUDO_CMD docker compose version &> /dev/null; then # Check if 'docker compose' (plugin) works
    print_warning "'docker compose' (plugin) not found or not working. Please ensure Docker Compose V2 is correctly installed and accessible."
    print_info "It's usually included with modern Docker installations. Check 'docker compose version'."
    exit 1
fi
print_success "Docker and Docker Compose seem to be available."

# --- Phase 2: Get Supabase Code ---
CURRENT_PHASE_NUM=$((CURRENT_PHASE_NUM + 1))
print_phase "$CURRENT_PHASE_NUM" "${E_BOX} Fetching Supabase Docker Configuration"

# Clean up previous attempts to ensure a fresh start
print_step "Cleaning up any previous '$SUPABASE_CODE_DIR' and '$PROJECT_DIR_NAME' directories"
run_command $SUDO_CMD rm -rf "$SUPABASE_CODE_DIR"
run_command $SUDO_CMD rm -rf "$PROJECT_DIR_NAME" # This will be the working dir
print_success "Cleanup complete."

if [ "$INSTALL_METHOD" == "general" ]; then
    print_step "Cloning Supabase repository (General method - shallow clone)"
    run_command git clone --depth 1 https://github.com/supabase/supabase "$SUPABASE_CODE_DIR"
    print_success "Supabase repository cloned (General method)."
else # Advanced method
    print_step "Cloning Supabase repository (Advanced method - sparse checkout prep)"
    run_command git clone --filter=blob:none --no-checkout https://github.com/supabase/supabase "$SUPABASE_CODE_DIR"
    print_step "Setting up sparse checkout for 'docker' directory"
    (cd "$SUPABASE_CODE_DIR" && run_command git sparse-checkout set --cone docker && run_command git checkout master)
    print_success "Supabase repository cloned and sparse checkout configured (Advanced method)."
fi

print_step "Creating project directory: '$PROJECT_DIR_NAME'"
run_command mkdir -p "$PROJECT_DIR_NAME"
print_success "Project directory '$PROJECT_DIR_NAME' created."

print_step "Copying Docker Compose files to '$PROJECT_DIR_NAME'"
run_command cp -rf "$SUPABASE_CODE_DIR/docker/"* "$PROJECT_DIR_NAME/"
print_success "Docker Compose files copied."

print_step "Copying .env.example to '$PROJECT_DIR_NAME/.env'"
run_command cp "$SUPABASE_CODE_DIR/docker/.env.example" "$PROJECT_DIR_NAME/.env"
print_success ".env file created from example."

print_step "Cleaning up temporary source directory '$SUPABASE_CODE_DIR'"
run_command $SUDO_CMD rm -rf "$SUPABASE_CODE_DIR"
print_success "Temporary source directory removed."

# --- Phase 3: Configure Supabase & Docker Compose ---
CURRENT_PHASE_NUM=$((CURRENT_PHASE_NUM + 1))
print_phase "$CURRENT_PHASE_NUM" "${E_GEAR} Configuring Supabase Environment"

# Change to project directory for subsequent Docker Compose commands
cd "$PROJECT_DIR_NAME"
PROJECT_ABS_PATH=$(pwd) # Get absolute path for clarity in messages
print_info "Changed working directory to: $PROJECT_ABS_PATH"

echo # Blank line for readability before next prompt
DEFAULT_DOCKER_SOCKET="/var/run/docker.sock"
prompt_user_select "The default Docker socket in .env is '$DEFAULT_DOCKER_SOCKET'. Do you need to change this (e.g., for rootless Docker)?" CHANGE_SOCKET "(y/N)"
if [[ "$CHANGE_SOCKET" =~ ^[yY](es|ES)?$ ]]; then
    prompt_user_select "Enter your Docker socket location (e.g., /run/user/1000/docker.sock)" DOCKER_SOCKET_PATH_CUSTOM "" # No default here
    if [ -n "$DOCKER_SOCKET_PATH_CUSTOM" ]; then
        print_step "Updating DOCKER_SOCKET_LOCATION in .env to '$DOCKER_SOCKET_PATH_CUSTOM'"
        run_command sed -i "s|^DOCKER_SOCKET_LOCATION=.*|DOCKER_SOCKET_LOCATION=${DOCKER_SOCKET_PATH_CUSTOM}|" .env
        print_success "DOCKER_SOCKET_LOCATION updated in .env."
    else
        print_warning "No custom Docker socket path entered. Using default from .env."
    fi
else
    print_info "Using default DOCKER_SOCKET_LOCATION from .env ('$DEFAULT_DOCKER_SOCKET')."
fi
echo

# --- Configure Public Supabase URLs based on ACCESS_TYPE ---
print_step "Configuring Supabase Public URLs (Site, API, Studio)"

# Define the target variables
TARGET_SITE_URL_VAR="SITE_URL"
TARGET_API_URL_VAR="API_EXTERNAL_URL"
TARGET_PUBLIC_URL_VAR="SUPABASE_PUBLIC_URL"

# Ports associated with the default URLs
DEFAULT_SITE_URL_PORT="3000"
DEFAULT_API_PUBLIC_URL_PORT="8000" # This is KONG_HTTP_PORT

# Initialize final URLs with localhost defaults
FINAL_SITE_URL="http://localhost:${DEFAULT_SITE_URL_PORT}"
FINAL_API_URL="http://localhost:${DEFAULT_API_PUBLIC_URL_PORT}"
FINAL_PUBLIC_URL="http://localhost:${DEFAULT_API_PUBLIC_URL_PORT}"

if [ "$ACCESS_TYPE" == "remote" ]; then
    print_info "Remote access selected. Configuring custom URLs."
    SERVER_IP_FOR_URL=$(get_primary_ip)

    if [ "$SERVER_IP_FOR_URL" != "NO_IP_FOUND" ]; then
        print_info "Detected server IP: ${C_BOLD}${SERVER_IP_FOR_URL}${C_OFF}"
        prompt_user_select "Use this auto-detected IP for Supabase public URLs (e.g., http://${SERVER_IP_FOR_URL}:<port>)?" USE_AUTO_IP "(Y/n)"

        if [[ "$USE_AUTO_IP" =~ ^[yY](es|ES)?$ ]] || [[ -z "$USE_AUTO_IP" ]]; then # Default to Yes
            FINAL_SITE_URL="http://${SERVER_IP_FOR_URL}:${DEFAULT_SITE_URL_PORT}"
            FINAL_API_URL="http://${SERVER_IP_FOR_URL}:${DEFAULT_API_PUBLIC_URL_PORT}"
            FINAL_PUBLIC_URL="http://${SERVER_IP_FOR_URL}:${DEFAULT_API_PUBLIC_URL_PORT}"
        else
            print_info "Manual URL configuration selected."
            prompt_user_select "Enter the base public URL for Supabase (e.g., http://your-server-ip or https://your.domain.com, without port)" MANUAL_BASE_URL ""
            if [ -n "$MANUAL_BASE_URL" ]; then
                FINAL_SITE_URL="${MANUAL_BASE_URL}:${DEFAULT_SITE_URL_PORT}"
                FINAL_API_URL="${MANUAL_BASE_URL}:${DEFAULT_API_PUBLIC_URL_PORT}"
                FINAL_PUBLIC_URL="${MANUAL_BASE_URL}:${DEFAULT_API_PUBLIC_URL_PORT}"
            else
                print_warning "No manual base URL entered. Default 'localhost' URLs will be used for remote setup, which is likely incorrect."
                # URLs remain localhost, user was warned
            fi
        fi
    else # IP not found for remote setup
        print_warning "Could not automatically determine server IP for remote setup."
        print_info "You will need to enter the base URL manually."
        prompt_user_select "Enter the base public URL for Supabase (e.g., http://your-server-ip or https://your.domain.com, without port)" MANUAL_BASE_URL ""
        if [ -n "$MANUAL_BASE_URL" ]; then
            FINAL_SITE_URL="${MANUAL_BASE_URL}:${DEFAULT_SITE_URL_PORT}"
            FINAL_API_URL="${MANUAL_BASE_URL}:${DEFAULT_API_PUBLIC_URL_PORT}"
            FINAL_PUBLIC_URL="${MANUAL_BASE_URL}:${DEFAULT_API_PUBLIC_URL_PORT}"
        else
            print_warning "No manual base URL entered. Default 'localhost' URLs will be used for remote setup, which is likely incorrect."
            # URLs remain localhost, user was warned
        fi
    fi

    # Update .env file only if remote access was chosen and URLs are not localhost
    print_info "Applying URL configuration to .env:"
    print_info "  ${TARGET_SITE_URL_VAR}=${C_BOLD}${FINAL_SITE_URL}${C_OFF}"
    print_info "  ${TARGET_API_URL_VAR}=${C_BOLD}${FINAL_API_URL}${C_OFF}"
    print_info "  ${TARGET_PUBLIC_URL_VAR}=${C_BOLD}${FINAL_PUBLIC_URL}${C_OFF}"

    if grep -q "^${TARGET_SITE_URL_VAR}=" .env; then
        run_command sed -i "s|^${TARGET_SITE_URL_VAR}=.*|${TARGET_SITE_URL_VAR}=${FINAL_SITE_URL}|" .env
        print_success "'${TARGET_SITE_URL_VAR}' updated."
    else
        print_warning "Variable '${TARGET_SITE_URL_VAR}' not found in .env."
    fi

    if grep -q "^${TARGET_API_URL_VAR}=" .env; then
        run_command sed -i "s|^${TARGET_API_URL_VAR}=.*|${TARGET_API_URL_VAR}=${FINAL_API_URL}|" .env
        print_success "'${TARGET_API_URL_VAR}' updated."
    else
        print_warning "Variable '${TARGET_API_URL_VAR}' not found in .env."
    fi

    if grep -q "^${TARGET_PUBLIC_URL_VAR}=" .env; then
        run_command sed -i "s|^${TARGET_PUBLIC_URL_VAR}=.*|${TARGET_PUBLIC_URL_VAR}=${FINAL_PUBLIC_URL}|" .env
        print_success "'${TARGET_PUBLIC_URL_VAR}' updated."
    else
        print_warning "Variable '${TARGET_PUBLIC_URL_VAR}' not found in .env."
    fi
else # Local access chosen
    print_info "Local access selected. Default 'localhost' URLs will be used:"
    print_info "  ${TARGET_SITE_URL_VAR}=${C_BOLD}${FINAL_SITE_URL}${C_OFF}"
    print_info "  ${TARGET_API_URL_VAR}=${C_BOLD}${FINAL_API_URL}${C_OFF}"
    print_info "  ${TARGET_PUBLIC_URL_VAR}=${C_BOLD}${FINAL_PUBLIC_URL}${C_OFF}"
    print_info "No changes made to .env for these URLs as defaults are 'localhost'."
fi
echo
# --- END Public URL Configuration ---

print_step "Pulling latest Docker images for Supabase (this may take a while)"
run_command_show_output $SUDO_CMD docker compose pull # Show output as it can be long
print_success "Docker images pulled."

print_step "Starting Supabase services in detached mode"
run_command $SUDO_CMD docker compose up -d
print_success "Supabase services started."

# --- Phase 4: Post-Installation & Verification ---
CURRENT_PHASE_NUM=$((CURRENT_PHASE_NUM + 1))
print_phase "$CURRENT_PHASE_NUM" "${E_CHECK} Post-Installation & Verification"

print_step "Waiting a few seconds for services to initialize..."
run_command sleep 15 # Give services some time to come up

print_step "Checking status of Supabase services:"
echo -e "${C_DIM}--- Docker Compose PS Output ---${C_OFF}"
$SUDO_CMD docker compose ps # Always show this output
echo -e "${C_DIM}--- End Docker Compose PS Output ---${C_OFF}"
print_info "All services should ideally show status 'running (healthy)' or 'running'."
print_info "If any service is 'created' but not running, try 'sudo docker compose start <service-name>' in '$PROJECT_ABS_PATH'."
echo

# --- Final Message ---
STUDIO_ACCESS_URL="$FINAL_API_URL"

echo -e "\n${C_GREEN}${C_BOLD}==============================================================${C_OFF}"
echo -e "${C_GREEN}${C_BOLD}      ${E_PARTY} Supabase Self-Hosting Setup Complete! ${E_PARTY}      ${C_OFF}"
echo -e "${C_GREEN}${C_BOLD}==============================================================${C_OFF}\n"

echo -e "${C_WHITE}You should now be able to access Supabase Studio:${C_OFF}"
if [ "$ACCESS_TYPE" == "local" ]; then
    echo -e "  Access URL (local): ${C_UNDERLINE}${C_BLUE}${STUDIO_ACCESS_URL}${C_OFF} ${E_LINK}"
    echo -e "  ${C_YELLOW}${E_INFO} Configured for local access. Access from the same machine where Docker is running.${C_OFF}"
elif [[ "$STUDIO_ACCESS_URL" == *"localhost"* ]]; then # Remote selected, but somehow still localhost (e.g. no manual input)
    SERVER_IP_HINT=$(get_primary_ip)
    echo -e "  Access URL (likely incorrect for remote): ${C_UNDERLINE}${C_BLUE}${STUDIO_ACCESS_URL}${C_OFF} ${E_LINK}"
    if [ "$SERVER_IP_HINT" != "NO_IP_FOUND" ]; then
        echo -e "  ${C_YELLOW}${E_WARN} URLs are set to 'localhost' despite remote setup. Try: ${C_UNDERLINE}${C_BLUE}http://${SERVER_IP_HINT}:${DEFAULT_API_PUBLIC_URL_PORT}${C_OFF}${C_OFF}"
    else
        echo -e "  ${C_YELLOW}${E_WARN} URLs are set to 'localhost' despite remote setup. You may need to use your server's actual IP or domain.${C_OFF}"
    fi
else # Remote selected and URL is not localhost
    echo -e "  Access URL (remote): ${C_UNDERLINE}${C_BLUE}${STUDIO_ACCESS_URL}${C_OFF} ${E_LINK}"
    echo -e "  (If not clickable, copy: ${STUDIO_ACCESS_URL})"
fi
echo

echo -e "${C_YELLOW}${C_BOLD}${E_SHIELD} IMPORTANT SECURITY NOTICE ${E_SHIELD}${C_OFF}"
echo -e "${C_YELLOW}Your Supabase instance is running with ${C_RED}${C_BOLD}DEFAULT INSECURE CREDENTIALS.${C_OFF}"
echo -e "${C_WHITE}Default Studio Credentials:${C_OFF}"
echo -e "  ${C_BOLD}Username:${C_OFF} supabase"
echo -e "  ${C_BOLD}Password:${C_OFF} this_password_is_insecure_and_should_be_updated"
echo
echo -e "${C_RED}${C_BOLD}You MUST change these credentials and secure your services AS SOON AS POSSIBLE!${C_OFF}"
echo -e "${C_WHITE}Refer to the official documentation for securing your instance:${C_OFF}"
echo -e "  ${C_UNDERLINE}${C_BLUE}https://supabase.com/docs/guides/self-hosting/docker#securing-your-services${C_OFF}"
echo -e "  ${C_UNDERLINE}${C_BLUE}https://supabase.com/docs/guides/self-hosting/docker#dashboard-authentication${C_OFF}"
echo

print_info "Supabase project files are located in: ${C_BOLD}${PROJECT_ABS_PATH}${C_OFF}"
print_info "To manage your Supabase services, navigate to this directory and use 'sudo docker compose [up|down|logs|ps|etc.]'."
echo -e "\n${C_CYAN}Enjoy your self-hosted Supabase instance! ${E_ROCKET}${C_OFF}\n"

exit 0