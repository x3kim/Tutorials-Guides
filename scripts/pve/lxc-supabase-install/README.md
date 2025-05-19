# Supabase Self-Hosting Easy Install Script 🚀☁️💾

<div>
  <a href="https://www.gnu.org/software/bash/" target="_blank">
    <img src="https://img.shields.io/badge/Language-Bash-blue?logo=gnubash&logoColor=white" alt="Language: Bash">
  </a>
  <a href="https://www.proxmox.com/en/proxmox-virtual-environment" target="_blank">
    <img src="https://img.shields.io/badge/Host%20Environment-Proxmox%20VE%20(LXC%20Target)-E07000?logo=proxmox&logoColor=white" alt="Host: Proxmox VE (LXC Target)">
  </a>
  <a href="https://www.debian.org/" target="_blank">
    <img src="https://img.shields.io/badge/Target%20OS-Debian%2FUbuntu%20(LXC)-orange?logo=debian&logoColor=white" alt="Target OS: Debian/Ubuntu (LXC)">
  </a>
  <a href="https://www.docker.com/" target="_blank">
    <img src="https://img.shields.io/badge/Requires-Docker%20&%20Compose-2496ED?logo=docker&logoColor=white" alt="Requires: Docker & Compose">
  </a>
  <a href="https://supabase.com/" target="_blank">
    <img src="https://img.shields.io/badge/Installs-Supabase%20Self--Hosted-3ECF8E?logo=supabase&logoColor=white" alt="Installs: Supabase Self-Hosted">
  </a>
  <a href="LICENSE" target="_blank"> <!-- Replace with your actual LICENSE file link -->
    <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT">
  </a>
</div>

---

## ⚡ Quick Install

For users who want to get started immediately and understand the implications.
The script will prompt you for the installation method (General/Advanced) and other options.

**Run these commands inside your Debian-based (LXC) container's terminal:**

1. Ensure `curl` and `git` are installed:

    ```bash
    sudo apt-get update && sudo apt-get install -y curl git
    ```

2. Execute the installation script:

    ```bash
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/x3kim/Tutorials-Guides-Templates-Collection/refs/heads/main/scripts/pve/lxc-supabase-install/install.sh)"
    ```

---

## 🚀 How to Use

**IMPORTANT: This script is designed to be run *inside* your Debian-based (LXC) container, NOT on the Proxmox VE host itself (if applicable). Docker and Docker Compose V2 (plugin) must be pre-installed.**

If you prefer to review the script before running it, or if the Quick Install method above doesn't suit your workflow, you can use the following steps:

### Download and Run (Inspect Before Running)

This method allows you to download the script and review it before execution.

1. **Ensure `curl` and `git` are installed in your container.**
    * If not, access your container's terminal and run:

        ```bash
        sudo apt-get update && sudo apt-get install -y curl git
        ```

2. **Access your container's terminal.**
3. **Download and Make Executable:**

    ```bash
    curl -LO https://raw.githubusercontent.com/x3kim/Tutorials-Guides-Templates-Collection/refs/heads/main/scripts/pve/lxc-supabase-install/install.sh
    chmod +x install.sh
    ```


4. **Run the Script:**

    ```bash
    ./install.sh
    ```

    If not root, you might be prompted for your `sudo` password. The script will then guide you through the setup options.

## ✨ Features

* **Automated Supabase Self-Hosted Setup:** Handles fetching Supabase Docker configurations, setting up the `.env` file, and launching services.
* **Choice of Installation Method:**
    * **General:** Quick clone of necessary files (recommended).
    * **Advanced:** Full clone with sparse-checkout for specific `docker` directory needs.
* **System Preparation:** Performs system updates and ensures `git` is installed.
* **User-Friendly Interface:**
    * Interactive choice for **Verbose Mode**.
    * Interactive choice for **Supabase Installation Method** (General/Advanced).
    * Prompts for **Docker Socket Location** for rootless Docker compatibility.
    * Color-coded output with emojis for clarity.
    * Automatic `sudo` handling.
* **`.env` Configuration:** Copies the example `.env` file and allows modification for the Docker socket.
* **Docker Compose Management:** Pulls necessary images and starts all Supabase services.
* **IP Address Detection:** Attempts to display the Supabase Studio access URL using the server's IP.
* **Post-Installation Guidance:** Provides default credentials and strong warnings to secure the instance.
* **Error Handling:** Exits on command failure (`set -e`).
* **Idempotency:** Cleans up temporary download directories and target project directory on re-runs to ensure a fresh setup.

## 📋 Prerequisites

* A Debian-based Linux system or **LXC container** (e.g., Debian, Ubuntu).
* **Docker and Docker Compose V2 (plugin) must be installed and operational.**
* Internet connection.
* **`curl` and `git`**: These tools are required (the script attempts to install `git` if missing, and `curl` is needed to fetch the script itself).
* Sudo privileges if not running as `root`.

## ⚙️ Script Overview

The script performs the following main actions:

1. **Initialization:**
    * Sets script behavior (e.g., `set -e`).
    * Defines UI elements (colors, emojis).
    * Prompts for **Verbose Mode** and **Installation Method**.
    * Checks for `root` privileges and prepares `sudo`.

2. **Helper Functions 🛠️:**
    * Standardized functions for output, user prompts, and command execution.

3. **Execution Phases:**

    * **Phase 1: 🔄 System Preparation & Prerequisite Checks**
        * Updates package lists.
        * Installs `git` if not present.
        * Verifies Docker and Docker Compose V2 are available.

    * **Phase 2: 📦 Fetching Supabase Docker Configuration**
        * Cleans up previous download/project directories.
        * Clones Supabase code based on chosen method (General: `git clone --depth 1`; Advanced: `git clone` with sparse-checkout).
        * Creates the `supabase-project` directory.
        * Copies Docker Compose files and `.env.example` into `supabase-project`.
        * Removes the temporary cloned source directory.

    * **Phase 3: ⚙️ Configuring Supabase Environment**
        * Changes to the `supabase-project` directory.
        * Prompts user to confirm or change `DOCKER_SOCKET_LOCATION` in `.env` (for rootless Docker).
        * Runs `docker compose pull` to fetch all Supabase service images.
        * Runs `docker compose up -d` to start services.

    * **Phase 4: ✅ Post-Installation & Verification**
        * Waits briefly for services to initialize.
        * Runs `docker compose ps` to display service status.
        * Displays final success message and access information for Supabase Studio.
        * **Crucially, warns about default insecure credentials and directs users to official security documentation.**

## 💡 Important Notes

* **Docker & Docker Compose Required:** This script **does not install Docker or Docker Compose**. They must be installed and working beforehand.
* **Run in Target Environment:** Best run directly on the server or LXC container where Supabase will reside.
* **Default Credentials:** Supabase Studio will be accessible with **default, insecure credentials**. **CHANGE THESE IMMEDIATELY** after installation.
    * Username: `supabase`
    * Password: `this_password_is_insecure_and_should_be_updated`
* **Security:** Refer to the official Supabase documentation for comprehensive steps on [Securing Your Services](https://supabase.com/docs/guides/self-hosting/docker#securing-your-services) and [Dashboard Authentication](https://supabase.com/docs/guides/self-hosting/docker#dashboard-authentication).
* **Firewall:** Ensure your firewall allows incoming connections on port `8000` (or other ports if you customize Supabase configuration later) to your server/LXC's IP address.
* **Project Directory:** All Supabase configuration and data (if using default Docker volumes) will reside within the `supabase-project` directory created by the script. Manage services from this directory using `sudo docker compose ...` commands.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Please ensure you understand the implications of self-hosting Supabase.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.