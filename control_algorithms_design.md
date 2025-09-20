# Intelligent Control Algorithms Design

## Overview

The intelligent control algorithms component is responsible for adjusting system parameters based on monitored data and user preferences. It implements the decision-making logic that optimizes power consumption while maintaining acceptable performance.

## Implementation Plan

### Control Structure

```
src/
├── control/
│   ├── __init__.py
│   ├── controller.py          # Main controller entry point
│   ├── algorithms/
│   │   ├── __init__.py
│   │   ├── cpu_controller.py  # CPU frequency scaling
│   │   ├── gpu_controller.py  # GPU frequency scaling
│   │   ├── display_controller.py  # Display brightness control
│   │   └── profile_manager.py # Profile switching logic
│   ├── policies/
│   │   ├── __init__.py
│   │   ├── performance.py     # Performance-oriented policies
│   │   ├── balanced.py        # Balanced power/performance policies
│   │   └── battery.py         # Battery-saving policies
│   └── decision_engine.py     # Central decision-making component
```

### Key Components

#### 1. Main Controller (controller.py)

- Implements the systemd service interface
- Manages the lifecycle of all control components
- Coordinates with the monitoring service
- Applies user-configured policies

#### 2. Algorithm Modules

Each controller module implements a standard interface:

```python
class ControllerInterface:
    def initialize(self, config) -> bool:
        """Initialize the controller with configuration, return True if successful"""
        pass
    
    def update(self, sensor_data) -> ControlAction:
        """Process sensor data and return control actions"""
        pass
    
    def cleanup(self):
        """Clean up any resources used by the controller"""
        pass
```

##### CPU Controller (cpu_controller.py)
- Implements CPU frequency scaling based on utilization and temperature
- Uses kernel CPU frequency scaling interface
- Applies hysteresis to prevent rapid frequency changes
- Considers current power profile

##### GPU Controller (gpu_controller.py)
- Controls GPU frequency and power states
- Uses AMD GPU specific interfaces
- Balances performance with power consumption
- Responds to temperature thresholds

##### Display Controller (display_controller.py)
- Adjusts display brightness based on battery level and ambient light
- Implements smooth brightness transitions
- Respects user manual brightness adjustments

#### 3. Policy Modules

Each policy defines how the system should behave under different conditions:

##### Performance Policy (performance.py)
- Prioritizes maximum performance
- Higher frequency thresholds
- Minimal power saving adjustments
- Aggressive boosting when needed

##### Balanced Policy (balanced.py)
- Maintains a balance between performance and battery life
- Moderate thresholds for adjustments
- Standard hysteresis values
- Typical user experience

##### Battery Policy (battery.py)
- Maximizes battery life
- Conservative frequency scaling
- Aggressive display dimming
- Reduced background activity

#### 4. Decision Engine (decision_engine.py)

Central component that coordinates control actions:

- Receives sensor data from monitoring service
- Applies configured policies
- Resolves conflicts between different controllers
- Implements override mechanisms
- Handles profile switching logic

### Control Algorithm Details

#### CPU Frequency Scaling

```
if temperature > critical_threshold:
    set_frequency(min_frequency)
elif utilization > boost_threshold and temperature < safe_threshold:
    set_frequency(max_frequency)
elif utilization < reduce_threshold:
    gradually_reduce_frequency()
else:
    maintain_current_frequency()
```

#### GPU Power Management

```
if temperature > critical_threshold:
    switch_to_low_power_state()
elif utilization > performance_threshold:
    switch_to_high_performance_state()
elif utilization < idle_threshold:
    switch_to_power_saving_state()
```

#### Display Brightness Control

```
if manual_brightness_adjustment_detected:
    pause_automatic_adjustments(temporary=True)
elif battery_level < critical_threshold:
    set_brightness(min(30%, current_brightness))
elif ambient_light_available:
    adjust_brightness_based_on_ambient_light()
elif battery_level < low_threshold:
    reduce_brightness_gradually()
```

## Integration with System

### Communication with Monitoring Service

- Connects to Unix domain socket provided by monitoring service
- Receives real-time sensor data
- Implements reconnect logic for service restarts

### Hardware Control Interfaces

- CPU frequency scaling through `/sys/devices/system/cpu/cpufreq/`
- GPU control through AMD GPU drivers
- Display brightness through sysfs interfaces

## Configuration Options

### Policy Thresholds

```json
{
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
    "brightness_step": 5
  }
}
```

## Profile Management

### Profile Switching Logic

- Automatic switching based on activity detection
- User manual overrides
- Scheduled profile changes
- Battery level based switching

### Profile Inheritance

Profiles can inherit from base profiles to reduce duplication:

```yaml
base:
  cpu:
    boost_threshold: 80
    reduce_threshold: 30
  gpu:
    performance_threshold: 70
    idle_threshold: 20

performance:
  inherits: base
  cpu:
    boost_threshold: 70  # Override base value
  gpu:
    performance_threshold: 60  # Override base value

battery_saver:
  inherits: base
  cpu:
    boost_threshold: 90  # Higher threshold means less boosting
    reduce_threshold: 20
  gpu:
    performance_threshold: 80  # Higher threshold means less performance
```

## Error Handling and Fallbacks

### Control Failure Handling

- If hardware control fails, log error and continue with next control loop
- Implement fallback values for critical systems
- Alert user interface of control failures
- Graceful degradation to safer settings

### Sensor Data Issues

- Handle missing or invalid sensor data
- Implement data interpolation for temporary sensor failures
- Use conservative defaults when sensor data is unavailable