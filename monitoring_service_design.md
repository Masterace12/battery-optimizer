# Core Monitoring Service Design

## Overview

The core monitoring service is responsible for continuously monitoring system parameters and providing this data to other components of the power management system. It runs as a systemd service with appropriate privileges to access hardware sensors.

## Implementation Plan

### Service Structure

```
src/
├── monitoring/
│   ├── __init__.py
│   ├── service.py          # Main service entry point
│   ├── sensors/
│   │   ├── __init__.py
│   │   ├── battery.py      # Battery monitoring
│   │   ├── cpu.py          # CPU monitoring
│   │   ├── gpu.py          # GPU monitoring
│   │   └── display.py      # Display monitoring
│   ├── data/
│   │   ├── __init__.py
│   │   └── models.py       # Data models for sensor readings
│   └── communication/
│       ├── __init__.py
│       └── socket_server.py # Unix socket server for data distribution
```

### Key Components

#### 1. Main Service (service.py)

- Implements the systemd service interface
- Manages the lifecycle of all monitoring components
- Handles graceful startup and shutdown
- Coordinates data collection intervals

#### 2. Sensor Modules

Each sensor module implements a standard interface:

```python
class SensorInterface:
    def initialize(self) -> bool:
        """Initialize the sensor, return True if successful"""
        pass
    
    def read(self) -> SensorData:
        """Read current sensor values and return structured data"""
        pass
    
    def cleanup(self):
        """Clean up any resources used by the sensor"""
        pass
```

##### Battery Sensor (battery.py)
- Reads from `/sys/class/power_supply/BAT1/`
- Monitors charge level, voltage, current, health
- Tracks charging state and charge cycles
- Calculates discharge rate

##### CPU Sensor (cpu.py)
- Reads from `/sys/devices/system/cpu/`
- Monitors frequency, temperature, and utilization
- Tracks per-core metrics
- Calculates average load

##### GPU Sensor (gpu.py)
- Queries AMD GPU metrics through appropriate interfaces
- Monitors frequency, temperature, and utilization
- Tracks power consumption

##### Display Sensor (display.py)
- Reads current brightness level
- Monitors display on/off state
- Tracks ambient light sensor (if available)

#### 3. Data Models (models.py)

Structured data representations for all sensor readings:

```python
@dataclass
class BatteryData:
    level: int          # Percentage
    charging: bool
    voltage: float      # Volts
    current: float      # Amps
    power: float        # Watts
    health: str         # Good, fair, poor
    temperature: float  # Celsius

@dataclass
class CPUData:
    frequency: int      # MHz
    temperature: float  # Celsius
    utilization: float  # Percentage
    cores: List[CoreData]

@dataclass
class GPUData:
    frequency: int      # MHz
    temperature: float  # Celsius
    utilization: float  # Percentage
    power: float        # Watts

@dataclass
class DisplayData:
    brightness: int     # Percentage
    ambient_light: int  # Lux (if available)
```

#### 4. Communication Layer (socket_server.py)

- Implements Unix domain socket server
- Distributes sensor data to clients (control algorithms, UI)
- Handles multiple concurrent connections
- Implements message framing for data integrity

## Systemd Integration

### Service File (/etc/systemd/system/steamdeck-power-monitor.service)

```ini
[Unit]
Description=Steam Deck Power Management Monitoring Service
After=multi-user.target
Requires=steamdeck-power-monitor.socket

[Service]
Type=simple
ExecStart=/usr/bin/steamdeck-power-monitor
Restart=always
RestartSec=5
User=root
Group=root

[Install]
WantedBy=multi-user.target
```

### Socket File (/etc/systemd/system/steamdeck-power-monitor.socket)

```ini
[Unit]
Description=Socket for Steam Deck Power Management Monitoring Service

[Socket]
ListenStream=/run/steamdeck-power-monitor.sock
SocketUser=root
SocketGroup=root
SocketMode=0660

[Install]
WantedBy=sockets.target
```

## Security Considerations

- Service runs as root to access hardware sensors
- Socket permissions restrict access to authorized users/groups
- Input validation on all data
- Secure handling of sensitive system information

## Performance Considerations

- Efficient polling intervals (configurable)
- Minimal processing in monitoring loop
- Caching of static information
- Asynchronous data distribution