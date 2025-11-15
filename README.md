# BOB Scripts

Scripts to install necessary software and configure all PCs in the CSEDU computer lab during Battle of Brains 2025 (Intra DU Programming Contest). This collection also includes firewall configuration to block internet access except for toph.co.

## Overview

This repository contains automated setup scripts for configuring contest machines with:
- Development tools and IDEs (VS Code, Sublime Text, CodeBlocks, etc.)
- Programming language compilers and debuggers
- User management (BOB25 user creation and system cleanup)
- Network firewall rules (restrict internet access to toph.co only)

## Quick Start

### Server Setup

1. **Start the server:**
   ```bash
   ./start_server.sh
   ```
   This will prompt for server IP and port, update configuration, and start a Python HTTP server.

2. **Access the web interface:**
   Open `http://<server_ip>:<port>/index.html` in a browser to access the interactive web interface with copy-paste commands.

### Client Setup (On Contest Machines)

The web interface provides three main setup steps:

1. **Step 1: Install Packages**
   ```bash
   bash <(wget -qO- http://<server_ip>:<port>/installer.sh)
   ```
   Installs: VS Code, Sublime Text, CodeBlocks, Python 3, OpenJDK 11, GDB, build-essential, and other development tools.

2. **Step 2: Create BOB25 User**
   ```bash
   bash <(wget -qO- http://<server_ip>:<port>/bob25.sh)
   ```
   - Deletes all users except the current user
   - Creates BOB25 user with password `allbatchtour`
   - Restricts BOB25 WiFi access (wired connections allowed)
   - Changes current user password (ask Ninad for the password)

3. **Step 3: Block Internet (Allow Only Toph.co)**
   ```bash
   sudo wget -qO /complete-toph-firewall.sh http://<server_ip>:<port>/complete-toph-firewall.sh && \
   sudo wget -qO /reset.sh http://<server_ip>:<port>/reset.sh && \
   sudo chmod +x /complete-toph-firewall.sh && \
   sudo /complete-toph-firewall.sh && \
   sudo chmod +x /reset.sh
   ```
   Configures firewall to allow access only to toph.co and related CDN domains. Firewall persists across reboots.

## Scripts Overview

### Main Setup Scripts

- **`installer.sh`** - Package installer
  - Downloads and installs development tools from server
  - Falls back to apt-get if server download fails
  - Supports custom server IP and port via command-line arguments

- **`bob25.sh`** - User management script
  - Deletes all users except current user
  - Creates BOB25 user with predefined password
  - Restricts WiFi access for BOB25 user
  - Changes current user password

- **`complete-toph-firewall.sh`** - Complete firewall setup
  - Blocks all internet except toph.co domains
  - Sets up persistent firewall via systemd service
  - Automatically applies on boot

### Utility Scripts

- **`start_server.sh`** - Interactive server startup
  - Prompts for IP and port configuration
  - Updates `config.sh` automatically
  - Regenerates `index.html` with current server URL
  - Starts Python HTTP server

- **`generate_index.sh`** - Web interface generator
  - Creates `index.html` with dynamic server URLs
  - Provides tabbed interface for setup and undo scripts
  - Includes copy-to-clipboard functionality

- **`change_server_ip.sh`** - Configuration updater
  - Updates server IP/port in `config.sh`
  - Regenerates `index.html`
  - Usage: `./change_server_ip.sh <new_ip> [port]`

- **`reset.sh`** - Firewall reset
  - Removes all firewall restrictions
  - Disables persistent firewall service
  - Restores full internet access

- **`cngpass.sh`** - Password changer
  - Changes current user password to 'student'
  - Bypasses Ubuntu password complexity requirements

### Configuration

- **`config.sh`** - Centralized configuration
  - Server IP, port, and URL settings
  - Exported variables for use in other scripts
  - Helper functions for accessing configuration

### Legacy/Archive Scripts

- **`dynamic-toph-firewall.sh`** - Dynamic firewall (legacy)
  - Generates iptables rules dynamically
  - Superseded by `complete-toph-firewall.sh`

- **`setup-persistent-firewall.sh`** - Persistence setup (legacy)
  - Sets up systemd service for firewall
  - Integrated into `complete-toph-firewall.sh`

## Configuration

### Server Configuration

Edit `config.sh` or use the interactive scripts:

```bash
# Manual edit
nano config.sh

# Or use interactive script
./start_server.sh

# Or use command-line tool
./change_server_ip.sh 192.168.1.100 8000
```

### Firewall Configuration

The firewall allows access to:
- `toph.co` and subdomains (www, api, cdn)
- Common CDN providers (Cloudflare, Fastly, AWS, Google CDN, jsDelivr)

To modify allowed domains, edit the `DOMAINS` array in `complete-toph-firewall.sh`.

## Undo/Reset Operations

### Reset Firewall
```bash
sudo /reset.sh
```
Completely removes firewall restrictions and disables persistent service.

### Change Password
```bash
sudo wget -qO /cngpass.sh http://<server_ip>:<port>/cngpass.sh && \
sudo chmod +x /cngpass.sh && \
sudo /cngpass.sh
```
Sets current user password to 'student'.

## Project Structure

```
BOB-Scripts/
├── README.md                      # This file
├── config.sh                      # Centralized configuration
├── index.html                     # Web interface (auto-generated)
├── start_server.sh                # Server startup script
├── generate_index.sh              # Web interface generator
├── change_server_ip.sh            # Configuration updater
├── installer.sh                   # Package installer
├── bob25.sh                       # User management script
├── complete-toph-firewall.sh      # Complete firewall setup
├── reset.sh                       # Firewall reset script
├── cngpass.sh                     # Password changer
├── dynamic-toph-firewall.sh       # Legacy dynamic firewall
├── setup-persistent-firewall.sh   # Legacy persistence setup
└── tukra scripts/                 # Archive/legacy scripts
    ├── block.txt
    ├── bob25 old.sh
    ├── delete_other_users.sh
    └── wifi.sh
```

## Requirements

### Server
- Python 3 (or Python 2) for HTTP server
- Bash shell
- Network access to serve files

### Client Machines
- Ubuntu/Debian-based Linux
- Internet access (for initial setup)
- sudo/root access
- `wget` (installed by installer.sh if missing)
- `dig` (for DNS resolution in firewall scripts)

## Usage Examples

### Basic Server Setup
```bash
# Start server with default settings
./start_server.sh
# Follow prompts to set IP and port

# Or specify directly
./change_server_ip.sh 10.33.23.159 8000
python3 -m http.server 8000
```

### Client Machine Setup (One-liner)
```bash
# Access web interface
# Open http://<server_ip>:8000/index.html
# Copy and paste commands from the interface
```

### Manual Script Execution
```bash
# Install packages
bash <(wget -qO- http://10.33.23.159:8000/installer.sh 10.33.23.159)

# Setup user
bash <(wget -qO- http://10.33.23.159:8000/bob25.sh)

# Setup firewall
sudo bash <(wget -qO- http://10.33.23.159:8000/complete-toph-firewall.sh)
```

## Troubleshooting

### Server Issues
- **Port already in use**: Use `start_server.sh` to find an available port
- **Can't access web interface**: Check firewall rules and ensure server IP is correct
- **Scripts not updating**: Run `generate_index.sh` after changing `config.sh`

### Client Issues
- **Package installation fails**: Scripts fall back to apt-get automatically
- **Firewall too restrictive**: Use `reset.sh` to restore internet access
- **User creation fails**: Ensure running with sudo/root privileges

### Firewall Issues
- **Can't access toph.co**: Check DNS resolution and verify domain IPs
- **Firewall not persistent**: Ensure `iptables-persistent` is installed
- **Service not starting**: Check systemd logs with `journalctl -u toph-firewall.service`

## Security Notes

- Scripts require sudo/root access for system modifications
- BOB25 user password is hardcoded: `allbatchtour`
- Current user password changes are documented (ask Ninad)
- Firewall rules are persistent and survive reboots
- WiFi restrictions use polkit policies

## Contributing

When adding new scripts:
1. Update `generate_index.sh` to include new scripts in web interface
2. Add documentation to this README
3. Test on a non-production machine first
4. Ensure scripts are idempotent (safe to run multiple times)

## License

Internal use for Battle of Brains 2025 contest setup.

## Contact

For issues or questions, contact Ninad or the CSEDU technical team.
