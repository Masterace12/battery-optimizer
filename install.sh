#!/bin/bash
# Steam Deck Power Manager Installation Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

echo -e "${GREEN}Installing Steam Deck Power Manager...${NC}"

# Create necessary directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p /usr/lib/steamdeck-power-manager
mkdir -p /etc/steamdeck-power-manager
mkdir -p /var/lib/steamdeck-power-manager
mkdir -p /var/log/steamdeck-power-manager

# Copy files
echo -e "${YELLOW}Copying files...${NC}"
cp -r steamdeck_power_manager/core /usr/lib/steamdeck-power-manager/
cp -r steamdeck_power_manager/control /usr/lib/steamdeck-power-manager/
cp -r steamdeck_power_manager/utils /usr/lib/steamdeck-power-manager/
cp steamdeck_power_manager/config/default_config.json /etc/steamdeck-power-manager/config.json
cp steamdeck_power_manager/service/*.service /etc/systemd/system/

# Set permissions
echo -e "${YELLOW}Setting permissions...${NC}"
chmod +x /usr/lib/steamdeck-power-manager/core/monitoring_service.py
chmod +x /usr/lib/steamdeck-power-manager/control/control_service.py

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