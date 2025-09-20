# Configuration System Design

## Overview

The configuration system manages user preferences, profiles, and system settings for the power management system. It provides a flexible and extensible way to customize the behavior of all components.

## Implementation Plan

### Configuration Structure

```
src/
├── config/
│   ├── __init__.py
│   ├── manager.py             # Main configuration manager
│   ├── models.py              # Configuration data models
│   ├── loader.py              # Configuration file loading and parsing
│   ├── validator.py           # Configuration validation
│   └── watcher.py             # File system watcher for live updates
```

### Configuration File Locations

1. **System Configuration**: `/etc/steamdeck-power-manager/config.json`
   - Default settings for all users
   - Read-only for regular users
   - Managed by system administrator or package manager

2. **User Configuration**: `~/.config/steamdeck-power-manager/config.json`
   - User-specific overrides
   - Read/write for user
   - Created on first run if not exists

3. **Profile Directory**: `/etc/steamdeck-power-manager/profiles/`
   - Predefined system profiles
   - Read-only for regular users

4. **User Profiles**: `~/.config/steamdeck-power-manager/profiles/`
   - User-created profiles
   - User-modifiable

### Configuration Data Models (models.py)

```python
from dataclasses import dataclass, field
from typing import Dict, List, Optional

@dataclass
class BatteryConfig:
    critical_level: int = 15
    low_level: int = 30
    medium_level: int = 60
    high_level: int = 85

@dataclass
class CPUConfig:
    boost_threshold: int = 80
    reduce_threshold: int = 30
    critical_temperature: int = 85
    safe_temperature: int = 75
    hysteresis: int = 5

@dataclass
class GPUConfig:
    performance_threshold: int = 70
    idle_threshold: int = 20
    critical_temperature: int = 80

@dataclass
class DisplayConfig:
    critical_battery_level: int = 15
    low_battery_level: int = 30
    brightness_step: int = 5
    ambient_light_enabled: bool = True

@dataclass
class ProfileConfig:
    name: str
    description: str = ""
    inherits: Optional[str] = None
    battery: BatteryConfig = field(default_factory=BatteryConfig)
    cpu: CPUConfig = field(default_factory=CPUConfig)
    gpu: GPUConfig = field(default_factory=GPUConfig)
    display: DisplayConfig = field(default_factory=DisplayConfig)
    enabled: bool = True

@dataclass
class AppConfig:
    monitoring_interval: int = 1000  # milliseconds
    control_interval: int = 5000     # milliseconds
    profiles: List[str] = field(default_factory=lambda: ["balanced"])
    default_profile: str = "balanced"
    auto_profile_switching: bool = True
    log_level: str = "INFO"
    enable_tray_icon: bool = True
```

### Configuration Manager (manager.py)

The main configuration manager handles loading, validation, and access to configuration data:

```python
class ConfigManager:
    def __init__(self):
        self.system_config_path = "/etc/steamdeck-power-manager/config.json"
        self.user_config_path = os.path.expanduser("~/.config/steamdeck-power-manager/config.json")
        self.config = AppConfig()
        self.profiles = {}
        self.watcher = ConfigWatcher()
    
    def load(self) -> bool:
        """Load configuration from system and user files"""
        pass
    
    def save(self) -> bool:
        """Save user configuration"""
        pass
    
    def get_profile(self, name: str) -> Optional[ProfileConfig]:
        """Get a profile by name"""
        pass
    
    def list_profiles(self) -> List[str]:
        """List all available profiles"""
        pass
    
    def validate(self) -> bool:
        """Validate configuration integrity"""
        pass
    
    def watch(self, callback):
        """Register callback for configuration changes"""
        pass
```

### Configuration Loader (loader.py)

Handles loading configuration from JSON/YAML files with support for inheritance:

```python
class ConfigLoader:
    @staticmethod
    def load_file(path: str) -> dict:
        """Load configuration from a file"""
        pass
    
    @staticmethod
    def resolve_inheritance(config: dict, base_path: str) -> dict:
        """Resolve profile inheritance"""
        pass
    
    @staticmethod
    def merge_configs(base: dict, override: dict) -> dict:
        """Merge two configuration dictionaries"""
        pass
```

### Configuration Validator (validator.py)

Ensures configuration values are within acceptable ranges:

```python
class ConfigValidator:
    @staticmethod
    def validate_app_config(config: AppConfig) -> List[str]:
        """Validate application configuration, return list of errors"""
        pass
    
    @staticmethod
    def validate_profile_config(profile: ProfileConfig) -> List[str]:
        """Validate profile configuration, return list of errors"""
        pass
    
    @staticmethod
    def validate_ranges(config: dict) -> List[str]:
        """Validate that numeric values are within acceptable ranges"""
        pass
```

### Configuration Watcher (watcher.py)

Monitors configuration files for changes and notifies listeners:

```python
class ConfigWatcher:
    def __init__(self):
        self.observers = []
        self.watcher = None  # Using watchdog or similar library
    
    def start_watching(self, paths: List[str]):
        """Start watching configuration files for changes"""
        pass
    
    def stop_watching(self):
        """Stop watching configuration files"""
        pass
    
    def add_observer(self, callback):
        """Add an observer to be notified of configuration changes"""
        pass
    
    def _on_file_changed(self, event):
        """Handle file change events"""
        pass
```

## Default Configuration Files

### System Configuration (/etc/steamdeck-power-manager/config.json)

```json
{
  "monitoring_interval": 1000,
  "control_interval": 5000,
  "profiles": ["performance", "balanced", "battery"],
  "default_profile": "balanced",
  "auto_profile_switching": true,
  "log_level": "INFO",
  "enable_tray_icon": true
}
```

### Default Profiles

#### Performance Profile (/etc/steamdeck-power-manager/profiles/performance.json)

```json
{
  "name": "performance",
  "description": "Maximum performance, reduced battery life",
  "cpu": {
    "boost_threshold": 70,
    "reduce_threshold": 20,
    "critical_temperature": 90,
    "safe_temperature": 80,
    "hysteresis": 3
  },
  "gpu": {
    "performance_threshold": 60,
    "idle_threshold": 10,
    "critical_temperature": 85
  },
  "display": {
    "critical_battery_level": 10,
    "low_battery_level": 20,
    "brightness_step": 3,
    "ambient_light_enabled": true
  }
}
```

#### Balanced Profile (/etc/steamdeck-power-manager/profiles/balanced.json)

```json
{
  "name": "balanced",
  "description": "Balanced performance and battery life",
  "cpu": {
    "boost_threshold": 80,
    "reduce_threshold": 30,
    "critical_temperature": 85,
    "safe_temperature": 75,
    "hysteresis": 5
  },
  "gpu": {
    "performance_threshold": 70,
    "idle_threshold": 20,
    "critical_temperature": 80
  },
  "display": {
    "critical_battery_level": 15,
    "low_battery_level": 30,
    "brightness_step": 5,
    "ambient_light_enabled": true
  }
}
```

#### Battery Profile (/etc/steamdeck-power-manager/profiles/battery.json)

```json
{
  "name": "battery",
  "description": "Maximum battery life, reduced performance",
  "cpu": {
    "boost_threshold": 90,
    "reduce_threshold": 25,
    "critical_temperature": 80,
    "safe_temperature": 70,
    "hysteresis": 7
  },
  "gpu": {
    "performance_threshold": 80,
    "idle_threshold": 15,
    "critical_temperature": 75
  },
  "display": {
    "critical_battery_level": 20,
    "low_battery_level": 40,
    "brightness_step": 7,
    "ambient_light_enabled": true
  }
}
```

## Configuration Schema

### JSON Schema for Validation

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "monitoring_interval": {
      "type": "integer",
      "minimum": 100,
      "maximum": 10000
    },
    "control_interval": {
      "type": "integer",
      "minimum": 1000,
      "maximum": 30000
    },
    "profiles": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "default_profile": {
      "type": "string"
    },
    "auto_profile_switching": {
      "type": "boolean"
    },
    "log_level": {
      "type": "string",
      "enum": ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
    },
    "enable_tray_icon": {
      "type": "boolean"
    }
  },
  "required": [
    "monitoring_interval",
    "control_interval",
    "profiles",
    "default_profile",
    "auto_profile_switching",
    "log_level",
    "enable_tray_icon"
  ]
}
```

## Integration with Other Components

### Loading at Startup

1. Configuration manager is initialized first in all services
2. System configuration is loaded
3. User configuration is loaded and merged with system configuration
4. Profile configurations are loaded
5. Configuration is validated
6. Services are started with validated configuration

### Live Updates

1. Configuration watcher monitors files for changes
2. When a change is detected, configuration is reloaded
3. Validation is performed on updated configuration
4. If valid, updated configuration is pushed to all components
5. If invalid, error is logged and previous configuration is retained

### Error Handling

1. If configuration files are missing, defaults are used
2. If configuration files are invalid, detailed error messages are logged
3. Fallback to previous valid configuration when possible
4. Critical configuration errors prevent service startup