# Installation System Design (Flatpak)

## Overview

The installation system packages the power management application for distribution via Flatpak, ensuring consistent installation across different Linux distributions while maintaining security and system integration.

## Implementation Plan

### Flatpak Structure

```
flatpak/
├── com.steamdeck.PowerManager.yaml    # Flatpak manifest
├── com.steamdeck.PowerManager.desktop  # Desktop entry
├── com.steamdeck.PowerManager.metainfo.xml  # AppStream metadata
├── systemd/                           # systemd unit files
│   ├── steamdeck-power-monitor.service
│   ├── steamdeck-power-monitor.socket
│   ├── steamdeck-power-control.service
│   └── steamdeck-power-control.socket
└── build.sh                           # Build script
```

### Flatpak Manifest (com.steamdeck.PowerManager.yaml)

```yaml
app-id: com.steamdeck.PowerManager
runtime: org.kde.Platform
runtime-version: '5.15-21.08'
sdk: org.kde.Sdk
command: steamdeck-power-manager
finish-args:
  # X11 access
  - --share=ipc
  - --socket=x11
  # Wayland access
  - --socket=wayland
  # System tray
  - --talk-name=org.kde.StatusNotifierWatcher
  # Notifications
  - --talk-name=org.freedesktop.Notifications
  # System bus access for systemd
  - --system-talk-name=org.freedesktop.systemd1
  # Hardware access (through helper service)
  - --socket=system-bus
  # File access
  - --filesystem=home
  # Network access for updates
  - --share=network

modules:
  - name: steamdeck-power-manager
    buildsystem: simple
    build-commands:
      - pip3 install --prefix=/app -r requirements.txt
      - install -Dm755 src/main.py /app/bin/steamdeck-power-manager
      - install -Dm644 flatpak/com.steamdeck.PowerManager.desktop /app/share/applications/com.steamdeck.PowerManager.desktop
      - install -Dm644 flatpak/com.steamdeck.PowerManager.metainfo.xml /app/share/metainfo/com.steamdeck.PowerManager.metainfo.xml
      - install -Dm644 ui/resources/icons/app-icon.svg /app/share/icons/hicolor/scalable/apps/com.steamdeck.PowerManager.svg
      # Install systemd unit files
      - install -Dm644 flatpak/systemd/steamdeck-power-monitor.service /app/share/systemd/steamdeck-power-monitor.service
      - install -Dm644 flatpak/systemd/steamdeck-power-monitor.socket /app/share/systemd/steamdeck-power-monitor.socket
      - install -Dm644 flatpak/systemd/steamdeck-power-control.service /app/share/systemd/steamdeck-power-control.service
      - install -Dm644 flatpak/systemd/steamdeck-power-control.socket /app/share/systemd/steamdeck-power-control.socket
    sources:
      - type: dir
        path: ..
      - type: file
        path: requirements.txt
```

### Desktop Entry (com.steamdeck.PowerManager.desktop)

```ini
[Desktop Entry]
Name=Steam Deck Power Manager
Comment=Intelligent power management for Steam Deck
Exec=steamdeck-power-manager
Icon=com.steamdeck.PowerManager
Terminal=false
Type=Application
Categories=System;Utility;
Keywords=power;battery;steam deck;performance;
```

### AppStream Metadata (com.steamdeck.PowerManager.metainfo.xml)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>com.steamdeck.PowerManager</id>
  <name>Steam Deck Power Manager</name>
  <summary>Intelligent power management for Steam Deck</summary>
  <description>
    <p>
      An autonomous power management system for the Steam Deck that optimizes 
      battery life while maintaining performance based on user preferences 
      and system conditions.
    </p>
    <p>Features:</p>
    <ul>
      <li>Real-time system monitoring (battery, CPU, GPU, temperature)</li>
      <li>Intelligent control algorithms for optimal power usage</li>
      <li>Configurable power profiles (performance, balanced, battery saver)</li>
      <li>System tray integration for quick access</li>
      <li>Real-time status display and historical data</li>
    </ul>
  </description>
  <categories>
    <category>System</category>
    <category>Utility</category>
  </categories>
  <keywords>
    <keyword>power</keyword>
    <keyword>battery</keyword>
    <keyword>steam deck</keyword>
    <keyword>performance</keyword>
    <keyword>optimization</keyword>
  </keywords>
  <url type="homepage">https://github.com/steamdeck-power-manager</url>
  <url type="bugtracker">https://github.com/steamdeck-power-manager/issues</url>
  <project_license>GPL-3.0</project_license>
  <developer_name>Steam Deck Community</developer_name>
  <screenshots>
    <screenshot type="default">
      <image>https://example.com/screenshot-settings.png</image>
      <caption>Settings window with configurable profiles</caption>
    </screenshot>
    <screenshot>
      <image>https://example.com/screenshot-status.png</image>
      <caption>Real-time system status display</caption>
    </screenshot>
  </screenshots>
  <releases>
    <release version="1.0.0" date="2023-01-01">
      <description>
        <p>Initial release with core functionality</p>
      </description>
    </release>
  </releases>
  <content_rating type="oars-1.1" />
</component>
```

## Systemd Service Installation

Since Flatpak applications run in a sandbox, we need a mechanism to install and manage systemd services that require system-level access.

### Privileged Helper Service

We'll implement a privileged helper service that runs outside the Flatpak sandbox:

```
src/
├── helper/
│   ├── __init__.py
│   ├── service.py              # Helper service entry point
│   ├── hardware_control.py     # Hardware control interface
│   └── dbus_service.py         # D-Bus service for communication
```

### D-Bus Interface

The helper service exposes a D-Bus interface that the Flatpak application can access:

```xml
<!-- com.steamdeck.PowerManager.Helper.xml -->
<node>
  <interface name="com.steamdeck.PowerManager.Helper">
    <method name="SetCPUFrequency">
      <arg type="u" name="frequency" direction="in"/>
      <arg type="b" name="success" direction="out"/>
    </method>
    <method name="SetGPUFrequency">
      <arg type="u" name="frequency" direction="in"/>
      <arg type="b" name="success" direction="out"/>
    </method>
    <method name="SetDisplayBrightness">
      <arg type="u" name="brightness" direction="in"/>
      <arg type="b" name="success" direction="out"/>
    </method>
    <method name="GetSystemInfo">
      <arg type="s" name="info" direction="out"/>
    </method>
  </interface>
</node>
```

### Installation Script

A post-installation script will set up the systemd services:

```bash
#!/bin/bash
# post-install.sh

# Copy systemd unit files to system locations
sudo cp /app/share/systemd/steamdeck-power-monitor.service /etc/systemd/system/
sudo cp /app/share/systemd/steamdeck-power-monitor.socket /etc/systemd/system/
sudo cp /app/share/systemd/steamdeck-power-control.service /etc/systemd/system/
sudo cp /app/share/systemd/steamdeck-power-control.socket /etc/systemd/system/

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable steamdeck-power-monitor.socket
sudo systemctl enable steamdeck-power-control.socket
sudo systemctl start steamdeck-power-monitor.socket
sudo systemctl start steamdeck-power-control.socket

# Set up D-Bus permissions
sudo cp /app/share/dbus-1/system.d/com.steamdeck.PowerManager.Helper.conf /etc/dbus-1/system.d/

# Add user to required groups
sudo usermod -a -G systemd-journal $USER
```

## Build Process

### Build Script (build.sh)

```bash
#!/bin/bash

# Create build directory
mkdir -p build

# Generate Flatpak manifest from template
envsubst < com.steamdeck.PowerManager.yaml.in > build/com.steamdeck.PowerManager.yaml

# Build the Flatpak
flatpak-builder --force-clean build-dir build/com.steamdeck.PowerManager.yaml

# Export to repository
flatpak-builder --export-only --gpg-sign=B9D16912 build-dir repo

# Create bundle
flatpak build-bundle repo steamdeck-power-manager.flatpak com.steamdeck.PowerManager
```

## Repository Management

### Flathub Submission

To distribute through Flathub:
1. Fork the Flathub repository
2. Add the application manifest
3. Submit a pull request
4. Address any review feedback
5. Merge and publish

### Self-Hosted Repository

For independent distribution:
```bash
# Initialize repository
flatpak build-init repo com.steamdeck.PowerManager

# Add builds to repository
flatpak build-export repo build-dir

# Generate summary
flatpak build-update-repo repo

# Host the repository through HTTP server
```

## Installation Instructions

### From Flathub
```bash
flatpak install flathub com.steamdeck.PowerManager
```

### From Bundle
```bash
flatpak install steamdeck-power-manager.flatpak
```

### From Repository
```bash
flatpak remote-add --if-not-exists steamdeck https://example.com/repo
flatpak install steamdeck com.steamdeck.PowerManager
```

## Updates

Flatpak handles updates automatically when installed from a repository:
```bash
flatpak update com.steamdeck.PowerManager
```

For bundle installations, users need to manually install updated bundles.

## Uninstallation

```bash
flatpak uninstall com.steamdeck.PowerManager
```

To completely remove:
```bash
flatpak uninstall --delete-data com.steamdeck.PowerManager
```

## Security Considerations

1. Minimal permissions in Flatpak manifest
2. Privileged operations through D-Bus service with policykit authentication
3. Secure communication between sandboxed and system components
4. Input validation on all interfaces
5. Regular security audits

## Integration Testing

### Automated Testing

1. Build the Flatpak in CI environment
2. Install in test container
3. Verify service installation and startup
4. Test D-Bus communication
5. Validate UI functionality

### Manual Testing

1. Clean installation on target systems
2. Verify systemd service integration
3. Test all UI components
4. Validate profile switching
5. Check notification system