# Steam Deck Power Manager - Project Summary

## Overview

We have successfully created a completely autonomous power management system for the Steam Deck that operates without any user interface. The system intelligently monitors and controls power usage to extend battery life during gaming sessions while maintaining optimal performance.

## Key Features Implemented

1. **Autonomous Operation**: Runs completely in the background without any user interface
2. **Real-time Monitoring**: Continuously monitors battery level, CPU/GPU temperature and usage, and display brightness
3. **Intelligent Control**: Automatically adjusts CPU frequency, GPU performance levels, and display brightness based on battery level and system conditions
4. **Power Profiles**: Three predefined profiles (Performance, Balanced, Battery Saver) that automatically switch based on battery level
5. **Dynamic Adjustments**: Makes real-time adjustments based on system conditions (temperature, battery level)
6. **Lightweight**: Minimal system overhead with efficient monitoring and control algorithms
7. **Enhanced AMD Support**: Uses AMD-PSTATE interfaces for better CPU control
8. **Improved Security**: Enhanced systemd service security with restricted permissions
9. **Configurable Paths**: Flexible configuration for different system setups

## Components

### 1. Monitoring Service
- Continuously collects system data from hardware sensors
- Monitors battery status, CPU/GPU temperature and usage, display brightness
- Uses AMD-PSTATE interfaces for better CPU monitoring
- Uses AMD-specific GPU interfaces for more accurate GPU usage monitoring
- Saves status information for the control service to use
- Runs as a systemd service

### 2. Control Service
- Adjusts system parameters based on the collected data and configured profiles
- Implements three power profiles with different settings for CPU, GPU, and display
- Uses AMD-PSTATE interfaces for better CPU control (EPP, boost, frequency limits)
- Automatically switches between profiles based on battery level and system conditions
- Runs as a systemd service

### 3. Configuration System
- JSON-based configuration file for easy customization
- Predefined power profiles that can be adjusted by users
- Configurable monitoring and control intervals
- Flexible file paths for different system configurations
- Configurable log file locations and levels

### 4. Installation System
- Simple installation script that sets up systemd services
- Uninstallation script to cleanly remove the program
- Flatpak manifest for alternative installation method
- AppImage creation script for portable installation

## Technologies Used

- **Python 3**: Core implementation language
- **systemd**: Service management
- **sysfs/procfs**: Hardware interface for monitoring and control
- **AMD-PSTATE**: Enhanced CPU frequency control for AMD processors
- **AMD GPU Interfaces**: Specific monitoring for RDNA2 GPU
- **JSON**: Configuration file format
- **Bash**: Installation scripts

## Installation Methods

1. **Direct Installation**: Using the provided install.sh script
2. **Flatpak**: Using the provided manifest
3. **AppImage**: Using the provided creation script

## File Structure

```
/home/deck/Documents/battery extender project/
├── steamdeck_power_manager/
│   ├── core/
│   │   └── monitoring_service.py
│   ├── control/
│   │   └── control_service.py
│   ├── config/
│   │   └── default_config.json
│   ├── utils/
│   │   └── helpers.py
│   ├── service/
│   │   ├── steamdeck-power-manager-monitor.service
│   │   └── steamdeck-power-manager-control.service
│   └── tests/
├── install.sh
├── uninstall.sh
├── README.md
├── LICENSE
└── ...
```

## How It Works

The Steam Deck Power Manager consists of two systemd services:

1. **Monitoring Service**: Continuously collects system data from hardware sensors using enhanced AMD-specific interfaces
2. **Control Service**: Adjusts system parameters based on the collected data and configured profiles using AMD-PSTATE interfaces

Both services run with enhanced security configurations and automatically start at boot time.

## Profile Switching Logic

The system automatically switches between profiles based on:

- **Performance Mode** (Battery > 70%): Maximum CPU/GPU frequencies, full brightness
- **Balanced Mode** (Battery 30-70%): Moderate CPU/GPU frequencies, balanced brightness
- **Battery Saver Mode** (Battery < 30%): Reduced CPU/GPU frequencies, dimmed display

Additional dynamic adjustments are made based on real-time conditions:

- Reduce brightness further when battery is critically low (< 15%)
- Reduce CPU frequency/boost when temperature is high (> 85°C)

## Security Enhancements

- Enhanced systemd service files with restricted capabilities
- Specific path permissions for hardware access
- Private temporary directories
- Protection against privilege escalation

## Testing

We've implemented comprehensive tests to verify:

- Python file compilation
- Configuration file parsing
- Directory structure
- Required files presence

## Improvements Made

1. **Enhanced CPU Monitoring**: Added AMD-PSTATE interfaces for better CPU monitoring
2. **Improved GPU Monitoring**: Added AMD-specific GPU monitoring interfaces
3. **Security Improvements**: Enhanced systemd service security with restricted permissions
4. **Configuration Flexibility**: Added configurable file paths for different system setups

## Conclusion

The Steam Deck Power Manager is a complete, autonomous solution for extending battery life on the Steam Deck during gaming sessions. It provides intelligent power management without any user interface distractions, allowing users to focus on their games while the system optimizes power usage in the background.

The implementation is modular, well-documented, and easy to install and customize. Users can adjust the configuration to suit their specific needs while benefiting from the automatic power optimization features. The enhancements we've made specifically for the Steam Deck's AMD hardware provide better control and monitoring capabilities than a generic solution.