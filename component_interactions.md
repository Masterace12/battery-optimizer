# Component Interactions

## Overview

This document describes how the various components of the Steam Deck Power Management System interact with each other to provide a cohesive power management solution.

## System Architecture Diagram

```
+------------------+     +-------------------+     +------------------+
|   User Interface |<--->| Configuration     |<--->| Control          |
|   (PyQt6)        |     | System (JSON/YAML)|     | Algorithms       |
+------------------+     +-------------------+     +------------------+
        ^                        ^                         ^
        |                        |                         |
        |                 +-----+-----+                   |
        |                 |           |                   |
        v                 v           v                   v
+------------------+     +-------------------+     +------------------+
| System Tray Icon |     | Profiles/Settings |     | Hardware Control |
+------------------+     +-------------------+     +------------------+
        ^                        ^                         ^
        |                        |                         |
        |                 +-----+-----+                   |
        |                 |           |                   |
        v                 v           v                   v
+------------------+     +-------------------+     +------------------+
|   Status Window  |     | File Watcher      |     | Kernel Interface |
+------------------+     +-------------------+     +------------------+
        ^                        ^                         ^
        |                        |                         |
        |                        v                         |
        |                 +-------------------+            |
        +---------------->| Core Monitoring   |<-----------+
                          | Service (systemd) |
                          +-------------------+
                                    ^
                                    |
                                    v
                          +-------------------+
                          | Hardware Sensors  |
                          | (sysfs, procfs)   |
                          +-------------------+
```

## Detailed Component Interactions

### 1. Core Monitoring Service Interactions

The Core Monitoring Service is the foundation of the system, continuously collecting hardware data and distributing it to other components.

```
[Hardware Sensors]
       |
       v
[Core Monitoring Service] <---> [Unix Domain Socket] <---> [Control Algorithms]
       |                                   ^
       |                                   |
       v                                   v
[systemd Journal]                   [User Interface]
```

**Interaction Flow:**
1. The Core Monitoring Service runs as a systemd service with root privileges
2. It reads hardware data from sysfs and procfs interfaces at regular intervals
3. Sensor data is published through a Unix domain socket
4. Control Algorithms and User Interface connect to this socket to receive real-time data
5. All components log to systemd journal for system-level logging

### 2. Configuration System Interactions

The Configuration System manages user preferences and provides them to all components.

```
[Config Files] --> [File Watcher] --> [Configuration Manager] --> [All Components]
     ^                                      |
     |                                      v
[User Interface] ------------------> [Config Updates]
```

**Interaction Flow:**
1. Configuration files are stored in system and user directories
2. File Watcher monitors for changes to configuration files
3. Configuration Manager loads and validates configurations
4. All components receive configuration data from the Configuration Manager
5. User Interface can modify configuration files through user interaction
6. File Watcher detects changes and notifies Configuration Manager
7. Configuration Manager pushes updates to all registered components

### 3. Control Algorithms Interactions

The Control Algorithms component makes decisions based on sensor data and configuration.

```
[Sensor Data] --> [Decision Engine] --> [Hardware Controllers] --> [System Hardware]
     ^                   ^                      ^
     |                   |                      |
     |            [Configuration]               |
     |                   |                      |
     |                   v                      |
[User Interface] --> [Policy Modules] --> [Control Actions]
```

**Interaction Flow:**
1. Decision Engine receives sensor data from Core Monitoring Service
2. Policy Modules provide rules based on current configuration/profile
3. Decision Engine applies policies to determine control actions
4. Hardware Controllers execute control actions on system hardware
5. User Interface can override or influence control decisions
6. All actions are logged for audit and debugging

### 4. User Interface Interactions

The User Interface provides user interaction points and displays system status.

```
[User Actions] --> [UI Components] --> [Backend Services]
     ^                    ^                  ^
     |                    |                  |
     |             [Configuration]           |
     |                    |                  |
     |                    v                  |
[System Status] <-- [UI Updates] <-- [Sensor Data]
```

**Interaction Flow:**
1. UI Components handle user interactions (button clicks, profile changes, etc.)
2. User actions are sent to appropriate backend services
3. UI receives real-time sensor data from Core Monitoring Service
4. Configuration Manager provides UI settings and profile information
5. UI displays system status and control options
6. System notifications are sent for important events

### 5. Installation System Interactions

The Installation System handles deployment and system integration.

```
[Flatpak Package] --> [Installation Script] --> [System Services]
      ^                        |                      ^
      |                        v                      |
[Build System]         [System Configuration] --> [Service Files]
```

**Interaction Flow:**
1. Build System creates Flatpak package with all application components
2. Installation Script extracts and installs system service files
3. System Configuration sets up appropriate permissions and directories
4. systemd manages the lifecycle of Core Monitoring and Control services
5. D-Bus provides communication between sandboxed UI and system services

### 6. Logging and Error Handling Interactions

The Logging and Error Handling system provides monitoring and debugging capabilities.

```
[All Components] --> [Logging System] --> [Log Files]
      ^                   ^                  ^
      |                   |                  |
      |            [Error Handlers]         |
      |                   |                  |
      |                   v                  |
[System Journal] <-- [Alert System] --> [Notifications]
```

**Interaction Flow:**
1. All components send log messages to the centralized Logging System
2. Logging System outputs to multiple destinations (files, system journal, etc.)
3. Error Handlers catch and process exceptions from all components
4. Alert System monitors for critical errors and sends notifications
5. System Journal integrates with systemd for system-level monitoring

## Data Flow Between Components

### Real-time Monitoring Data Flow

```
1. Hardware Sensors
   |
   v
2. Core Monitoring Service (reads sensor data)
   |
   v
3. Unix Domain Socket (publishes data)
   |
   +-> 4a. Control Algorithms (decision making)
   |
   +-> 4b. User Interface (status display)
   |
   +-> 4c. Logging System (data logging)
```

### Configuration Data Flow

```
1. Configuration Files (system/user)
   |
   v
2. Configuration Manager (loads and validates)
   |
   +-> 3a. Core Monitoring Service (monitoring intervals)
   |
   +-> 3b. Control Algorithms (policy parameters)
   |
   +-> 3c. User Interface (UI settings)
```

### Control Action Data Flow

```
1. Control Algorithms (decisions based on sensor data + config)
   |
   v
2. Hardware Controllers (execute system changes)
   |
   v
3. System Hardware (actual frequency, brightness changes)
   |
   v
4. Feedback to Sensors (new values detected)
```

## Communication Protocols

### Unix Domain Sockets

Used for inter-process communication between services:
- Core Monitoring Service publishes sensor data
- Control Algorithms subscribe to sensor data
- Bidirectional communication for control commands

### D-Bus

Used for communication between sandboxed UI and system services:
- Hardware control requests from UI to privileged services
- System status updates from services to UI

### File System

Used for configuration and data persistence:
- JSON/YAML configuration files
- Log files
- Runtime data files

## Security Boundaries

### Privileged Components

```
Root Privileges Required:
+--------------------------+
| Core Monitoring Service  |
| Control Algorithms       |
| System Service Installers|
+--------------------------+
```

### Sandboxed Components

```
User Privileges Only:
+--------------------------+
| User Interface           |
| Configuration Manager    |
| Logging System           |
+--------------------------+
```

Communication between these security domains uses:
1. D-Bus for controlled privilege escalation
2. Unix domain sockets for same-privilege communication
3. File system with appropriate permissions

## Error Handling Boundaries

Each component implements error handling at its boundaries:

1. **Hardware Interface Layer**: Handles sensor read failures, permission errors
2. **Service Layer**: Manages service startup/shutdown, recovery from failures
3. **Communication Layer**: Handles network errors, message format issues
4. **User Interface Layer**: Manages user input validation, UI state errors

## Performance Considerations

### Asynchronous Communication

Components use asynchronous communication where possible:
- Unix domain sockets for non-blocking data transfer
- Threading for concurrent operations
- Event loops for UI responsiveness

### Data Flow Optimization

- Sensor data is published via efficient binary protocols
- Configuration updates are incremental
- Control actions are batched when appropriate
- Caching is used for frequently accessed data

## Update Mechanisms

### Hot Configuration Updates

```
[File Watcher] --> [Configuration Manager] --> [Component Notification]
```

When configuration files change:
1. File Watcher detects changes
2. Configuration Manager validates and loads new configuration
3. Components receive update notifications
4. Services adjust behavior without restart

### Service Updates

```
[Package Manager] --> [Service Manager] --> [Component Restart]
```

When services are updated:
1. Package manager installs new versions
2. Service manager handles graceful restart
3. Components reinitialize with new code
4. Connections are reestablished

## Monitoring and Debugging

### Health Checks

Each component provides health status:
- Core Monitoring Service: Sensor availability
- Control Algorithms: Decision engine status
- User Interface: UI responsiveness
- Configuration System: File access status

### Diagnostic Data Flow

```
[Diagnostic Request] --> [Component Status] --> [Aggregated Report]
```

Diagnostic tools can query each component for:
- Current status and metrics
- Recent errors and warnings
- Configuration values
- Performance statistics

This comprehensive interaction design ensures that all components work together efficiently while maintaining clear boundaries and robust error handling.