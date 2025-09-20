# Steam Deck Power Manager

An autonomous power management system for the Steam Deck that intelligently monitors and controls power usage to extend battery life during gaming sessions.

## Features

- **Autonomous Operation**: Runs completely in the background without any user interface
- **Real-time Monitoring**: Continuously monitors battery level, CPU/GPU temperature and usage, and display brightness
- **Intelligent Control**: Automatically adjusts CPU frequency, GPU performance levels, and display brightness based on battery level and system conditions
- **Power Profiles**: Three predefined profiles (Performance, Balanced, Battery Saver) that automatically switch based on battery level
- **Dynamic Adjustments**: Makes real-time adjustments based on system conditions (temperature, battery level)
- **Lightweight**: Minimal system overhead with efficient monitoring and control algorithms
- **Enhanced AMD Support**: Uses AMD-PSTATE interfaces for better CPU control on Steam Deck's Ryzen processor
- **Improved Security**: Enhanced systemd service security with restricted permissions
- **Configurable Paths**: Flexible configuration for different system setups

## Enhanced Features

### AMD-PSTATE Support
The Steam Deck Power Manager now uses AMD-PSTATE interfaces for better CPU control:
- **Energy Performance Preference (EPP)**: Controls the balance between performance and power efficiency
- **CPU Boost Control**: Enables/disables CPU boost based on conditions
- **Advanced Frequency Management**: Uses AMD-specific interfaces for better frequency control
- **GPU Usage Monitoring**: Uses AMD-specific interfaces for more accurate GPU usage monitoring

### Security Enhancements
- **Restricted Capabilities**: Systemd services use only necessary capabilities
- **Private Temporary Directories**: Isolated temporary file systems for services
- **Protected System Directories**: Services cannot modify critical system files
- **No New Privileges**: Prevents privilege escalation attacks

### Configuration Flexibility
- **Configurable File Paths**: All file paths can be customized for different system setups
- **Flexible Logging**: Configurable log file locations and levels
- **Profile Customization**: All power profile parameters can be adjusted

## Installation

1. Clone or download this repository
2. Run the installation script with root privileges:
   ```bash
   sudo ./install.sh
   ```

## Usage

After installation, the Steam Deck Power Manager will automatically start and run in the background. The system will:

1. Monitor battery level, CPU/GPU temperature and usage every 5 seconds
2. Automatically switch between power profiles based on battery level:
   - **Performance Mode** (Battery > 70%): Maximum CPU/GPU frequencies, full brightness
   - **Balanced Mode** (Battery 30-70%): Moderate CPU/GPU frequencies, balanced brightness
   - **Battery Saver Mode** (Battery < 30%): Reduced CPU/GPU frequencies, dimmed display
3. Make dynamic adjustments based on real-time conditions:
   - Reduce brightness further when battery is critically low (< 15%)
   - Reduce CPU frequency/boost when temperature is high (> 85°C)

## Configuration

The configuration file is located at `/etc/steamdeck-power-manager/config.json`. You can modify:

- Monitoring and control intervals
- Power profile settings (CPU governor, EPP, frequency limits, boost, GPU performance levels, brightness)
- File paths for different system configurations
- Log level and file locations

After modifying the configuration, restart the services:
```bash
sudo systemctl restart steamdeck-power-manager-monitor.service
sudo systemctl restart steamdeck-power-manager-control.service
```

## Monitoring

You can check the status of the services with:
```bash
systemctl status steamdeck-power-manager-monitor.service
systemctl status steamdeck-power-manager-control.service
```

Logs are available at:
- `/var/log/steamdeck-power-manager/combined.log` (both services)
- Or separate logs if configured: `/var/log/steamdeck-power-manager/monitor.log` and `/var/log/steamdeck-power-manager/control.log`

Current system status is saved to:
- `/var/lib/steamdeck-power-manager/status.json`

## Uninstallation

To uninstall, run the uninstallation script with root privileges:
```bash
sudo ./uninstall.sh
```

## How It Works

The Steam Deck Power Manager consists of two systemd services:

1. **Monitoring Service**: Continuously collects system data from hardware sensors using enhanced AMD-specific interfaces
2. **Control Service**: Adjusts system parameters based on the collected data and configured profiles using AMD-PSTATE interfaces

Both services run with enhanced security configurations and automatically start at boot time.

## Supported Hardware

This software is designed specifically for the Steam Deck (LCD and OLED versions) running SteamOS or other Linux distributions.

## License

This project is licensed under the MIT License - see the LICENSE file for details.