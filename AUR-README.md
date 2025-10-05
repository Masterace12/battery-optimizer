# Steam Deck Power Manager for AUR

## Installation

To install this package, you can use an AUR helper like `yay`, `paru`, or similar:

```bash
yay -S steamdeck-power-manager
```

Or clone and build manually:

```bash
git clone https://aur.archlinux.org/steamdeck-power-manager.git
cd steamdeck-power-manager
makepkg -si
```

## Configuration

After installation, the configuration file is located at:
- `/etc/steamdeck-power-manager/config.json`

You can modify the power profiles, monitoring intervals, and other settings in this file.
After making changes, restart the services:

```bash
sudo systemctl restart steamdeck-power-manager-monitor.service
sudo systemctl restart steamdeck-power-manager-control.service
```

## Services

The package installs two systemd services:

1. `steamdeck-power-manager-monitor.service` - Monitors system data
2. `steamdeck-power-manager-control.service` - Applies power profiles

Check status with:
```bash
systemctl status steamdeck-power-manager-*.service
```

## Uninstallation

To remove the package:
```bash
sudo pacman -R steamdeck-power-manager
```

This will stop and disable the systemd services automatically.

## Dependencies

- `python` - Python 3 runtime
- `python-psutil` - System monitoring library
- `systemd` - Service management

Optional:
- `radeontop` - For more accurate GPU usage monitoring

## License

This project is licensed under the MIT License - see the LICENSE file for details.