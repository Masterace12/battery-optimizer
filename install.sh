#!/bin/bash
# Steam Deck Power Manager Installation Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to validate paths to prevent path traversal vulnerabilities
validate_path() {
    local path="$1"
    if [[ "$path" == *".."* ]] || [[ "$path" == *"/../"* ]]; then
        echo -e "${RED}Error: Invalid path contains '..' - possible path traversal attempt${NC}" >&2
        exit 1
    fi
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

echo -e "${GREEN}Installing Steam Deck Power Manager...${NC}"

# Validate source paths to prevent path traversal
validate_path "steamdeck_power_manager/core"
validate_path "steamdeck_power_manager/control"
validate_path "steamdeck_power_manager/utils"
validate_path "steamdeck_power_manager/__init__.py"
validate_path "steamdeck_power_manager/config/default_config.json"
validate_path "steamdeck_power_manager/service"

# Create necessary directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p /usr/lib/steamdeck-power-manager
mkdir -p /etc/steamdeck-power-manager
mkdir -p /var/lib/steamdeck-power-manager
mkdir -p /var/log/steamdeck-power-manager

# Set secure permissions on sensitive directories
chmod 750 /var/log/steamdeck-power-manager
chmod 750 /var/lib/steamdeck-power-manager
chmod 750 /etc/steamdeck-power-manager
chown root:root /var/log/steamdeck-power-manager
chown root:root /var/lib/steamdeck-power-manager
chown root:root /etc/steamdeck-power-manager

# Copy files
echo -e "${YELLOW}Copying files...${NC}"
cp -r steamdeck_power_manager/core /usr/lib/steamdeck-power-manager/
cp -r steamdeck_power_manager/control /usr/lib/steamdeck-power-manager/
cp -r steamdeck_power_manager/utils /usr/lib/steamdeck-power-manager/
cp steamdeck_power_manager/__init__.py /usr/lib/steamdeck-power-manager/
cp steamdeck_power_manager/config/default_config.json /etc/steamdeck-power-manager/config.json
cp steamdeck_power_manager/service/*.service /etc/systemd/system/

# Set secure permissions on config file
chmod 640 /etc/steamdeck-power-manager/config.json

# Set permissions on executable files
echo -e "${YELLOW}Setting permissions...${NC}"
chmod +x /usr/lib/steamdeck-power-manager/core/monitoring_service.py
chmod +x /usr/lib/steamdeck-power-manager/control/control_service.py
chmod +x /usr/lib/steamdeck-power-manager/utils/helpers.py

# Create systemd services
echo -e "${YELLOW}Enabling systemd services...${NC}"
systemctl daemon-reload
systemctl enable steamdeck-power-manager-monitor.service
systemctl enable steamdeck-power-manager-control.service

# Start services
echo -e "${YELLOW}Starting services...${NC}"
systemctl start steamdeck-power-manager-monitor.service
systemctl start steamdeck-power-manager-control.service

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${GREEN}The Steam Deck Power Manager is now running.${NC}"
echo -e "${GREEN}Services:${NC}"
echo -e "  - Monitoring service: systemctl status steamdeck-power-manager-monitor.service"
echo -e "  - Control service: systemctl status steamdeck-power-manager-control.service"
echo -e "${GREEN}Configuration file is located at: /etc/steamdeck-power-manager/config.json${NC}"
echo -e "${GREEN}Logs are available at: /var/log/steamdeck-power-manager/${NC}"