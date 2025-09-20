#!/bin/bash
# Steam Deck Power Manager Uninstallation Script

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

echo -e "${YELLOW}Uninstalling Steam Deck Power Manager...${NC}"

# Stop services
echo -e "${YELLOW}Stopping services...${NC}"
systemctl stop steamdeck-power-manager-monitor.service || true
systemctl stop steamdeck-power-manager-control.service || true

# Disable services
echo -e "${YELLOW}Disabling services...${NC}"
systemctl disable steamdeck-power-manager-monitor.service || true
systemctl disable steamdeck-power-manager-control.service || true

# Remove systemd service files
echo -e "${YELLOW}Removing systemd service files...${NC}"
rm -f /etc/systemd/system/steamdeck-power-manager-monitor.service
rm -f /etc/systemd/system/steamdeck-power-manager-control.service

# Reload systemd
echo -e "${YELLOW}Reloading systemd...${NC}"
systemctl daemon-reload

# Remove files and directories
echo -e "${YELLOW}Removing files and directories...${NC}"
rm -rf /usr/lib/steamdeck-power-manager
rm -rf /etc/steamdeck-power-manager
rm -rf /var/lib/steamdeck-power-manager

echo -e "${GREEN}Uninstallation complete!${NC}"