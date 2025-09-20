#!/bin/bash
# AppImage creation script for Steam Deck Power Manager

set -e

# Create AppDir structure
mkdir -p SteamDeckPowerManager.AppDir/usr/lib/steamdeck-power-manager
mkdir -p SteamDeckPowerManager.AppDir/etc/steamdeck-power-manager
mkdir -p SteamDeckPowerManager.AppDir/var/lib/steamdeck-power-manager

# Copy files
cp -r core SteamDeckPowerManager.AppDir/usr/lib/steamdeck-power-manager/
cp -r control SteamDeckPowerManager.AppDir/usr/lib/steamdeck-power-manager/
cp -r utils SteamDeckPowerManager.AppDir/usr/lib/steamdeck-power-manager/
cp config/default_config.json SteamDeckPowerManager.AppDir/etc/steamdeck-power-manager/config.json

# Create launcher script
cat > SteamDeckPowerManager.AppDir/AppRun << 'EOF'
#!/bin/bash
# Steam Deck Power Manager AppImage launcher

echo "Steam Deck Power Manager"
echo "========================"
echo "To install the systemd services, extract this AppImage and run:"
echo "  sudo cp usr/lib/steamdeck-power-manager/service/*.service /etc/systemd/system/"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable steamdeck-power-manager-monitor.service"
echo "  sudo systemctl enable steamdeck-power-manager-control.service"
echo "  sudo systemctl start steamdeck-power-manager-monitor.service"
echo "  sudo systemctl start steamdeck-power-manager-control.service"
EOF

chmod +x SteamDeckPowerManager.AppDir/AppRun

# Create desktop file
cat > SteamDeckPowerManager.AppDir/steamdeck-power-manager.desktop << 'EOF'
[Desktop Entry]
Name=Steam Deck Power Manager
Exec=steamdeck-power-manager
Type=Application
Categories=System;
EOF

# Create AppImage (this would require appimagetool to be installed)
echo "To create the AppImage, install appimagetool and run:"
echo "  appimagetool SteamDeckPowerManager.AppDir"