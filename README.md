<div align="center">

<!-- Animated Typing Banner -->
<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=28&duration=3000&pause=1000&color=2E9EF7&center=true&vCenter=true&multiline=true&repeat=true&width=600&height=100&lines=Backend+Assistant;8+Agents+%7C+2+Skills;Claude+Code+Plugin" alt="Backend Assistant" />

<br/>

<!-- Badge Row 1: Status Badges -->
[![Version](https://img.shields.io/badge/Version-2.0.0-blue?style=for-the-badge)](https://github.com/pluginagentmarketplace/custom-plugin-backend/releases)
[![License](https://img.shields.io/badge/License-Custom-yellow?style=for-the-badge)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production-brightgreen?style=for-the-badge)](#)
[![SASMP](https://img.shields.io/badge/SASMP-v1.3.0-blueviolet?style=for-the-badge)](#)

<!-- Badge Row 2: Content Badges -->
[![Agents](https://img.shields.io/badge/Agents-8-orange?style=flat-square&logo=robot)](#-agents)
[![Skills](https://img.shields.io/badge/Skills-2-purple?style=flat-square&logo=lightning)](#-skills)
[![Commands](https://img.shields.io/badge/Commands-4-green?style=flat-square&logo=terminal)](#-commands)

<br/>

<!-- Quick CTA Row -->
[📦 **Install Now**](#-quick-start) · [🤖 **Explore Agents**](#-agents) · [📖 **Documentation**](#-documentation) · [⭐ **Star this repo**](https://github.com/pluginagentmarketplace/custom-plugin-backend)

---

### What is this?

> **Backend Assistant** is a Claude Code plugin with **8 agents** and **2 skills** for backend development.

</div>

---

## 📑 Table of Contents

<details>
<summary>Click to expand</summary>

- [Quick Start](#-quick-start)
- [Features](#-features)
- [Agents](#-agents)
- [Skills](#-skills)
- [Commands](#-commands)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [License](#-license)

</details>

---

## 🚀 Quick Start

### Prerequisites

- Claude Code CLI v2.0.27+
- Active Claude subscription

### Installation (Choose One)

<details open>
<summary><strong>Option 1: From Marketplace (Recommended)</strong></summary>

```bash
# Step 1️⃣ Add the marketplace
/plugin add marketplace pluginagentmarketplace/custom-plugin-backend

# Step 2️⃣ Install the plugin
/plugin install backend-development-assistant@pluginagentmarketplace-backend

# Step 3️⃣ Restart Claude Code
# Close and reopen your terminal/IDE
```

</details>

<details>
<summary><strong>Option 2: Local Installation</strong></summary>

```bash
# Clone the repository
git clone https://github.com/pluginagentmarketplace/custom-plugin-backend.git
cd custom-plugin-backend

# Load locally
/plugin load .

# Restart Claude Code
```

</details>

### ✅ Verify Installation

After restart, you should see these agents:

```
backend-development-assistant:01-programming-fundamentals
backend-development-assistant:07-testing-security
backend-development-assistant:03-api-development
backend-development-assistant:04-architecture-patterns
backend-development-assistant:02-database-management
... and 2 more
```

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🤖 **8 Agents** | Specialized AI agents for backend tasks |
| 🛠️ **2 Skills** | Reusable capabilities with Golden Format |
| ⌨️ **4 Commands** | Quick slash commands |
| 🔄 **SASMP v1.3.0** | Full protocol compliance |

---

## 🤖 Agents

### 8 Specialized Agents

| # | Agent | Purpose |
|---|-------|---------|
| 1 | **01-programming-fundamentals** | Master programming languages, package management, and versio |
| 2 | **07-testing-security** | Comprehensive testing strategies (unit, integration, E2E, co |
| 3 | **03-api-development** | Design and build professional APIs with REST, GraphQL, and g |
| 4 | **04-architecture-patterns** | Master system architecture, SOLID principles, 23 GoF design  |
| 5 | **02-database-management** | Master database systems including relational (PostgreSQL, My |
| 6 | **06-devops-infrastructure** | Deploy applications with Docker and Kubernetes, set up CI/CD |
| 7 | **05-caching-performance** | Optimize application and database performance through cachin |

---

## 🛠️ Skills

### Available Skills

| Skill | Description | Invoke |
|-------|-------------|--------|
| `databases` | Master relational and NoSQL databases. Learn PostgreSQL, MyS | `Skill("backend-development-assistant:databases")` |
| `devops` | Deploy applications with Docker and Kubernetes, automate wit | `Skill("backend-development-assistant:devops")` |
| `security` | Secure backend applications against OWASP threats. Implement | `Skill("backend-development-assistant:security")` |
| `api-design` | Design and build professional APIs with REST, GraphQL, and g | `Skill("backend-development-assistant:api-design")` |
| `languages` | Master programming languages for backend development. Learn  | `Skill("backend-development-assistant:languages")` |
| `architecture` | Master architectural design with SOLID principles, design pa | `Skill("backend-development-assistant:architecture")` |
| `performance` | Optimize application performance through caching strategies, | `Skill("backend-development-assistant:performance")` |

---

## ⌨️ Commands

| Command | Description |
|---------|-------------|
| `/learn` | Start learning backend development. Choose a learning path a |
| `/assess` | Assess your knowledge and readiness for each agent. Take ass |
| `/browse-agent` | Browse available agents in the custom-plugin-backend system. |
| `/projects` | View all hands-on projects across the 7 agents. Get project  |

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |
| [LICENSE](LICENSE) | License information |

---

## 📁 Project Structure

<details>
<summary>Click to expand</summary>

```
custom-plugin-backend/
├── 📁 .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── 📁 agents/              # 8 agents
├── 📁 skills/              # 2 skills (Golden Format)
├── 📁 commands/            # 4 commands
├── 📁 hooks/
├── 📄 README.md
├── 📄 CHANGELOG.md
└── 📄 LICENSE
```

</details>

---

## 📅 Metadata

| Field | Value |
|-------|-------|
| **Version** | 2.0.0 |
| **Last Updated** | 2025-12-29 |
| **Status** | Production Ready |
| **SASMP** | v1.3.0 |
| **Agents** | 8 |
| **Skills** | 2 |
| **Commands** | 4 |

---

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md).

1. Fork the repository
2. Create your feature branch
3. Follow the Golden Format for new skills
4. Submit a pull request

---

## ⚠️ Security

> **Important:** This repository contains third-party code and dependencies.
>
> - ✅ Always review code before using in production
> - ✅ Check dependencies for known vulnerabilities
> - ✅ Follow security best practices
> - ✅ Report security issues privately via [Issues](../../issues)

---

## 📝 License

Copyright © 2025 **Dr. Umit Kacar** & **Muhsin Elcicek**

Custom License - See [LICENSE](LICENSE) for details.

---

## 👥 Contributors

<table>
<tr>
<td align="center">
<strong>Dr. Umit Kacar</strong><br/>
Senior AI Researcher & Engineer
</td>
<td align="center">
<strong>Muhsin Elcicek</strong><br/>
Senior Software Architect
</td>
</tr>
</table>

---

<div align="center">

**Made with ❤️ for the Claude Code Community**

[![GitHub](https://img.shields.io/badge/GitHub-pluginagentmarketplace-black?style=for-the-badge&logo=github)](https://github.com/pluginagentmarketplace)

</div>
