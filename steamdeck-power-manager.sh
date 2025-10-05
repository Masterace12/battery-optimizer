#!/bin/bash
# Wrapper script for Steam Deck Power Manager

echo "Steam Deck Power Manager"
echo "========================"
echo "For manual installation, please use the systemd services directly."
echo "The installation script will handle this automatically, but if installing"
echo "manually, copy the service files to /etc/systemd/system/ and enable them with:"
echo "  sudo systemctl enable steamdeck-power-manager-monitor.service"
echo "  sudo systemctl enable steamdeck-power-manager-control.service"
echo "  sudo systemctl start steamdeck-power-manager-monitor.service"
echo "  sudo systemctl start steamdeck-power-manager-control.service"