# My Tech Toolbox: Scripts, Guides & Templates 🛠️📚

Welcome to my personal collection of scripts, guides, and templates! This repository serves as my digital toolbox, organizing useful utilities, setup procedures, and reusable configurations. The goal is to streamline my workflows and potentially share helpful resources with others.

---

## 🧰 Available Resources

This collection is organized into different categories. Click on a category or resource name to explore.

### ⚙️ Automation Scripts

Scripts designed to automate setup processes, configurations, or repetitive tasks.

<details>
<summary>🐳 Docker & Portainer (Proxmox VE LXC)</summary>

* [**Automated Docker & Portainer Installation for Proxmox LXC**](./scripts/pve/lxc-docker-portainer-install/install.sh)
  * This Bash script automates the complete installation of Docker and offers an **interactive choice to also install Portainer CE** within a Debian-based Proxmox VE LXC container. It handles system updates/upgrades, dependency installation, and Docker repository setup. **If Portainer installation is chosen,** it also manages its volume creation and attempts to display the Portainer access URL with the server's IP. The script offers an interactive verbose mode.
  * **Functionality:** LXC Setup, Docker Install, **Portainer Install (User Choice)**
  * **Tags:** `Proxmox VE`, `LXC`, `Docker`, `Portainer`, `Bash`, `Automation`, `Server Setup`, `Containerization`, `Debian`, `Ubuntu`

</details>

*(More scripts will be added here in the future!)*

---

### 📙 Guides & Tutorials

Step-by-step instructions, explanations, and best practice guides for various tools and technologies.

<details>
<summary>📚 LM Studio</summary>

* [**Model Integration with Symlinks**](./guides/LM-Studio/LM-Studio-LLM-symlinks/README.md) ⛔ **Needs revision.**
  * This guide explains how to efficiently manage models in LM Studio using symbolic links. This method helps save disk space and improves organization, especially if you use models across multiple AI applications.
  * **Resource Type:** Guide
  * **Tags:** `Windows`, `PowerShell`, `Symlinks`, `LLM`, `LM Studio`, `Model Management`, `AI`

</details>

<details>
<summary>🍃 Paperless-ngx</summary>

* [**Document Type Guide & Suggestions**](./guides/Paperless-ngx/Paperless-ngx_document_types/README.md)
  * This guide provides recommended document types for organizing your digital documents in Paperless-ngx, aiming for a balance between specificity and generality. It offers suggestions for types, tags, and correspondents to help you find your files easily.
  * **Resource Type:** Guide
  * **Tags:** `Paperless-ngx`, `Document Management`, `Organization`, `Document Types`, `Tags`

</details>

*(More guides will be added here in the future!)*

---

<!--
### 📄 Templates (Example section if you add some)

Reusable configuration files, project starters, or document templates.

<details>
<summary>#### 📝 Example Template</summary>

*   [**My Awesome Config Template**](./templates/example_template/config.example.json)
    *   A brief description of what this template is for.
    *   **Resource Type:** Configuration Template
    *   **Tags:** `JSON`, `Configuration`, `Example`
</details>
-->

## 🤝 Contributing

While this is primarily a personal collection, suggestions, corrections, or contributions are welcome! Please feel free to create an "Issue" or a "Pull Request" if you have ideas for improvements or new additions.

---

## 📜 License

This project is licensed under the [MIT License](./LICENSE).