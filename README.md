# MSG - Message Management Tool

A sophisticated command-line tool for managing, searching, and retrieving message templates, responses, and documentation. Designed for support teams and operations personnel who need quick access to standardized messages, escalation procedures, and useful resources.

---

## 📋 Table of Contents

- [Features](#-features)
- [System Requirements](#-system-requirements)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Usage Guide](#-usage-guide)
- [Configuration](#️-configuration)
- [Data Management](#-data-management)
- [Advanced Features](#-advanced-features)
- [Troubleshooting](#-troubleshooting)
- [License](#-license)

---

## 🚀 Features

### Core Capabilities

- **Fast ID-Based Lookup**: Retrieve messages instantly by ID (e.g., `msg rsp1`)
- **Intelligent Keyword Search**: AI-powered search with stemming and text decomposition
- **Multiple Data Sources**: Organize messages by category (responses, escalations, workflows, URLs)
- **Customizable Configuration**: Override defaults without modifying base settings
- **Color-Coded Output**: Easy-to-read terminal display with syntax highlighting
- **Session Management**: Coordinated output from multiple data sources

### Smart Search Features

- **NLTK-Powered Stemming**: Finds "running" when you search for "run"
- **Term Decomposition**: Matches "ai-studio" with searches for "ai" or "studio"
- **Ranking Algorithm**: Shows most relevant results first
- **Configurable Result Limits**: Control how many results to display
- **Flag-Based Filtering**: Search specific file types (e.g., `-r` for responses only)

### Management Features

- **Auto-Upgrade System**: Update to latest version with `msg --upgrade`
- **Self-Initialization**: Validates dependencies and configuration
- **Custom Config Support**: Add your own messages without modifying defaults
- **Safe Uninstallation**: Complete removal with backup protection
- **Version Control**: Track installed version and check for updates

---

## 💻 System Requirements

### Minimum Requirements

- **OS**: macOS (darwin_arm64) - Apple Silicon M1/M2/M3
- **Python**: 3.8 or higher (Python 3.11+ recommended)
- **Git**: Latest version
- **Terminal**: Bash or Zsh
- **Disk Space**: ~50MB for installation and dependencies

### Dependencies (Auto-Installed)

- **PyYAML** >= 6.0 - YAML configuration parsing
- **nltk** >= 3.8.1 - Natural language processing
- **requests** >= 2.31.0 (optional) - HTTP requests
- **yq** >= 3.1.0 (optional) - YAML/JSON processing

---

## 📦 Installation

This repository hosts the installer script that fetches the complete MSG application.

### Prerequisites

Before installing, ensure you have **Python 3 (3.8+)** and **Git** installed.

### One-Line Installation

Execute the following command in your terminal to download and run the installer:

```bash
curl -sSL https://raw.githubusercontent.com/ooluwgb/msg/main/bin/install.sh | bash
```

### Manual Installation Steps (If curl | bash fails)

#### 1. Download the Installation Script

```bash
curl -o install.sh https://raw.githubusercontent.com/ooluwgb/msg/main/bin/install.sh
```

#### 2. Run the Installer

```bash
chmod +x install.sh
./install.sh
```

### Installation Process

The installer checks system compatibility, installs dependencies, and sets up global command access.

### Verify Installation

```bash
# Check version
msg --version

# Test basic functionality
msg --help
```

---

## 🎯 Quick Start

### Basic Commands

```bash
# List all available messages
msg

# Get a specific message by ID
msg rsp1

# Search for messages by keyword
msg payment billing

# Search with result limit
msg incident 3

# Mix ID lookup and keyword search
msg rsp1 payment

# Use flags to filter by category
msg -r customer           # Search only response files
msg -e escalation         # Search only escalate files
msg --all-files keyword   # Search all files
```

### Common Use Cases

#### 1. Get a Customer Response Template

```bash
msg rsp2
# Output: Change Payer Type To Company template
```

#### 2. Find All Payment-Related Messages

```bash
msg payment
# Output: Ranked list of payment-related entries
```

#### 3. Search Multiple Categories

```bash
msg -rw billing
# Searches both response and workflow files for "billing"
```

---

## 📖 Usage Guide

### Command Syntax

```bash
msg [OPTIONS] [IDs] [KEYWORDS] [LIMIT]
msg [UTILITY_COMMANDS]
```

### Core Commands

#### 1. List Mode (No Arguments)

Display all available entries:

```bash
msg
```

#### 2. ID Lookup (Direct Retrieval)

Fetch specific entries by ID:

```bash
# Single ID
msg rsp1

# Multiple IDs
msg rsp1 esc2 url5

# IDs are case-insensitive
msg RSP1 Esc2 URL5
```

#### 3. Keyword Search (Intelligent Matching)

Search by tags and keywords:

```bash
# Single keyword
msg payment

# Multiple keywords (AND logic)
msg payment billing operations

# With result limit
msg payment 3
```

### File Filtering Flags

Filter search by message category:

| Flag | Category | Description |
|------|----------|-------------|
| `-r` | Response | Customer response templates |
| `-e` | Escalate | Escalation procedures |
| `-w` | Workflow | Workflow URLs and processes |
| `-g` | Grafana | Grafana dashboard links |
| `-d` | DataLens | DataLens analytics URLs |
| `-n` | NPC | Service/NPC information |
| `-u` | URL | Useful URLs and resources |
| `--all-files` | All | Search across all files |

**Examples:**

```bash
# Search only response files
msg -r customer issue

# Search response and escalate files
msg -re incident

# Search everything
msg --all-files keyword
```

### Utility Commands

#### Version Management

```bash
# Check current version
msg --version

# Upgrade to latest version
msg --upgrade

# Force reinstall
msg --upgrade --force
```

#### Configuration Management

```bash
# Set default files to load
msg --set-default -r          # Load response files by default
msg --set-default --all-files # Load all files by default
```

#### System Management

```bash
# Initialize/validate system
msg --init

# Uninstall (requires confirmation)
msg --uninstall
```

---

## ⚙️ Configuration

### Configuration Files

MSG uses a two-tier configuration system:

- **Base Configuration** (`~/.msg/config/config.yaml`): System defaults that should not be modified directly.
- **Custom Configuration** (`~/.msg/custom_config.yaml`): User overrides that are preserved during upgrades and take precedence over base config.

### Custom Configuration Examples

Edit `~/.msg/custom_config.yaml` to customize settings:

```yaml
# Change default files to load
default_loaded_response_files:
  - response.json
  - escalate.json

# Adjust search result limit
max_display_results: 5
```

### Directory Structure

The installer creates the following structure under your home directory:

```
~/.msg/
├── bin/                      # Executable scripts
├── config/                   # Configuration files (base)
├── custom_config.yaml        # User configuration (custom overrides)
├── default_load/             # Default message files
├── custom_load/              # User message files (custom)
└── .nltk_data/               # NLTK language data
```

---

## 📊 Data Management

### Message File Format

Message files are JSON arrays containing entries with the following **required fields**: `id`, `description`, and `tags`.

The main content must be provided under one of the supported field names:

| Field Name | Purpose |
|------------|---------|
| `content` | General message content |
| `message` | Message text |
| `workflow_url` | Workflow process URL |
| `grafana_url` | Grafana dashboard URL |
| `datalens_url` | DataLens analytics URL |
| `usefull_url` | Useful resource URL |

### ID Naming Conventions

The system recognizes several prefixes for ID lookup:

| Prefix | Category | Example IDs |
|--------|----------|-------------|
| `rsp` | Response | rsp1, rsp2, rsp3 |
| `esc` | Escalate | esc1, esc2, esc3 |
| `wrk` | Workflow | wrk1, wrk2, wrk3 |
| `grf` | Grafana | grf1, grf2, grf3 |
| `dtl` | DataLens | dtl1, dtl2, dtl3 |
| `npc` | NPC/Service | npc1, npc2, npc3 |
| `url` | URLs | url1, url2, url3 |

---

## 🔧 Advanced Features

### Architecture Summary

The core system is built on distinct components communicating via a session protocol:

- **dispatcher**: Routes commands and coordinates the process.
- **msg_id**: Handles high-priority exact ID matches.
- **msg_tag**: Executes intelligent keyword searching and ranking.
- **printer**: Formats and displays combined, sorted output.

### Fallback Modes

- **If the Printer is Unavailable**, output falls back to raw JSON directly to the terminal.
- **If NLTK is Missing**, the search still works but uses simpler string matching instead of intelligent stemming.

---

## 🐛 Troubleshooting

### Common Issues

| Symptom | Cause | Solution |
|---------|-------|----------|
| **Command Not Found: msg** | PATH variable not updated or symlink failed. | Run `source ~/.zshrc` (or `~/.bashrc`) or restart your terminal. |
| **NLTK Data Missing** | Language data download failed during install. | Run `msg --upgrade` to reinstall dependencies. |

### Getting Help

- **General Help**: Run `msg --help`
- **Specific Command Help**: Run `msg --help --upgrade` or `msg --help -r`
- **Force Clean Upgrade**: Run `msg --upgrade --force`
- **Validate Installation**: Run `msg --init`

---

## 📄 License

This project is licensed under the **Apache License 2.0**.

- You are free to use, modify, and distribute the software.
- You must retain the original copyright and license notice.

---

Made with ❤️ for support teams who need quick access to information.

**MSG** - Because good communication shouldn't be hard to find.