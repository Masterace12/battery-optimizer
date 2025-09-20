# Logging and Error Handling Design

## Overview

The logging and error handling system provides comprehensive logging capabilities and robust error handling for all components of the power management system, enabling effective debugging, monitoring, and troubleshooting.

## Implementation Plan

### Logging Structure

```
src/
├── logging/
│   ├── __init__.py
│   ├── logger.py              # Main logger implementation
│   ├── handlers.py            # Custom log handlers
│   ├── formatters.py          # Custom log formatters
│   └── config.py              # Logging configuration
```

### Logger Implementation (logger.py)

```python
import logging
import logging.handlers
import sys
from typing import Optional
import os

class PowerManagerLogger:
    def __init__(self, name: str = "steamdeck-power-manager"):
        self.logger = logging.getLogger(name)
        self.logger.setLevel(logging.DEBUG)
        
        # Prevent adding handlers multiple times
        if not self.logger.handlers:
            self._setup_handlers()
    
    def _setup_handlers(self):
        """Set up logging handlers"""
        # Console handler for development
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.INFO)
        console_formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        console_handler.setFormatter(console_formatter)
        self.logger.addHandler(console_handler)
        
        # File handler for persistent logging
        log_dir = os.path.expanduser("~/.local/share/steamdeck-power-manager/logs")
        os.makedirs(log_dir, exist_ok=True)
        log_file = os.path.join(log_dir, "power-manager.log")
        
        file_handler = logging.handlers.RotatingFileHandler(
            log_file, maxBytes=10*1024*1024, backupCount=5
        )
        file_handler.setLevel(logging.DEBUG)
        file_formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s'
        )
        file_handler.setFormatter(file_formatter)
        self.logger.addHandler(file_handler)
        
        # Try to set up systemd journal handler if available
        try:
            from systemd.journal import JournalHandler
            journal_handler = JournalHandler()
            journal_handler.setLevel(logging.INFO)
            journal_formatter = logging.Formatter(
                '%(name)s - %(levelname)s - %(message)s'
            )
            journal_handler.setFormatter(journal_formatter)
            self.logger.addHandler(journal_handler)
        except ImportError:
            # systemd journal not available, skip
            pass
    
    def debug(self, message: str):
        self.logger.debug(message)
    
    def info(self, message: str):
        self.logger.info(message)
    
    def warning(self, message: str):
        self.logger.warning(message)
    
    def error(self, message: str):
        self.logger.error(message)
    
    def critical(self, message: str):
        self.logger.critical(message)
    
    def exception(self, message: str):
        self.logger.exception(message)

# Global logger instance
logger = PowerManagerLogger()
```

### Custom Handlers (handlers.py)

```python
import logging
import logging.handlers
import threading
import queue
from typing import Any

class AsyncLogHandler(logging.Handler):
    """Asynchronous logging handler to prevent blocking"""
    
    def __init__(self, handler: logging.Handler):
        super().__init__()
        self.handler = handler
        self.queue = queue.Queue()
        self.thread = threading.Thread(target=self._process_logs, daemon=True)
        self.thread.start()
    
    def emit(self, record: logging.LogRecord):
        try:
            self.queue.put_nowait(record)
        except queue.Full:
            # If queue is full, drop the log record
            pass
    
    def _process_logs(self):
        while True:
            try:
                record = self.queue.get(timeout=1)
                self.handler.emit(record)
                self.queue.task_done()
            except queue.Empty:
                continue
            except Exception:
                # If there's an error in the handler, we don't want to crash
                pass

class RateLimitHandler(logging.Handler):
    """Handler that limits the rate of log messages"""
    
    def __init__(self, handler: logging.Handler, max_messages_per_minute: int = 60):
        super().__init__()
        self.handler = handler
        self.max_messages = max_messages_per_minute
        self.message_count = 0
        self.reset_time = threading.Timer(60, self._reset_count)
        self.reset_time.start()
        self.lock = threading.Lock()
    
    def emit(self, record: logging.LogRecord):
        with self.lock:
            if self.message_count < self.max_messages:
                self.handler.emit(record)
                self.message_count += 1
            else:
                # Log that we're dropping messages
                if self.message_count == self.max_messages:
                    self.handler.emit(
                        logging.makeLogRecord({
                            'name': 'RateLimitHandler',
                            'levelno': logging.WARNING,
                            'levelname': 'WARNING',
                            'msg': f'Rate limit exceeded, dropping log messages. Limit: {self.max_messages}/minute'
                        })
                    )
                    self.message_count += 1  # Prevent repeated warnings
    
    def _reset_count(self):
        with self.lock:
            self.message_count = 0
        self.reset_time = threading.Timer(60, self._reset_count)
        self.reset_time.start()
```

### Custom Formatters (formatters.py)

```python
import logging
import json
from datetime import datetime

class JSONFormatter(logging.Formatter):
    """Formatter that outputs log records as JSON"""
    
    def format(self, record: logging.LogRecord) -> str:
        log_entry = {
            'timestamp': datetime.fromtimestamp(record.created).isoformat(),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno
        }
        
        # Add exception information if present
        if record.exc_info:
            log_entry['exception'] = self.formatException(record.exc_info)
        
        # Add extra fields if present
        if hasattr(record, '__dict__'):
            for key, value in record.__dict__.items():
                if key not in ['name', 'msg', 'args', 'levelname', 'levelno', 
                              'pathname', 'filename', 'module', 'lineno', 
                              'funcName', 'created', 'msecs', 'relativeCreated', 
                              'thread', 'threadName', 'processName', 'process',
                              'exc_info', 'exc_text', 'stack_info']:
                    log_entry[key] = value
        
        return json.dumps(log_entry)

class ColoredFormatter(logging.Formatter):
    """Formatter that adds colors to console output"""
    
    COLORS = {
        'DEBUG': '\033[36m',    # Cyan
        'INFO': '\033[32m',     # Green
        'WARNING': '\033[33m',  # Yellow
        'ERROR': '\033[31m',    # Red
        'CRITICAL': '\033[35m'  # Magenta
    }
    RESET = '\033[0m'
    
    def format(self, record: logging.LogRecord) -> str:
        # Add color to level name
        if record.levelname in self.COLORS:
            record.levelname = f"{self.COLORS[record.levelname]}{record.levelname}{self.RESET}"
        
        return super().format(record)
```

### Logging Configuration (config.py)

```python
import logging.config
import os
from typing import Dict, Any

def get_logging_config(log_level: str = "INFO") -> Dict[str, Any]:
    """Get logging configuration dictionary"""
    
    log_dir = os.path.expanduser("~/.local/share/steamdeck-power-manager/logs")
    os.makedirs(log_dir, exist_ok=True)
    
    return {
        'version': 1,
        'disable_existing_loggers': False,
        'formatters': {
            'standard': {
                'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            },
            'detailed': {
                'format': '%(asctime)s - %(name)s - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s'
            },
            'json': {
                '()': 'src.logging.formatters.JSONFormatter'
            }
        },
        'handlers': {
            'console': {
                'class': 'logging.StreamHandler',
                'level': log_level,
                'formatter': 'standard',
                'stream': 'ext://sys.stdout'
            },
            'file': {
                'class': 'logging.handlers.RotatingFileHandler',
                'level': 'DEBUG',
                'formatter': 'detailed',
                'filename': os.path.join(log_dir, 'power-manager.log'),
                'maxBytes': 10*1024*1024,
                'backupCount': 5
            },
            'json_file': {
                'class': 'logging.handlers.RotatingFileHandler',
                'level': 'DEBUG',
                'formatter': 'json',
                'filename': os.path.join(log_dir, 'power-manager.json'),
                'maxBytes': 10*1024*1024,
                'backupCount': 5
            }
        },
        'loggers': {
            '': {  # root logger
                'handlers': ['console', 'file'],
                'level': 'DEBUG',
                'propagate': False
            },
            'steamdeck.powermanager.monitoring': {
                'handlers': ['file', 'json_file'],
                'level': 'INFO',
                'propagate': False
            },
            'steamdeck.powermanager.control': {
                'handlers': ['file', 'json_file'],
                'level': 'INFO',
                'propagate': False
            },
            'steamdeck.powermanager.ui': {
                'handlers': ['console', 'file'],
                'level': 'INFO',
                'propagate': False
            }
        }
    }

def setup_logging(config_manager):
    """Set up logging based on configuration"""
    log_level = config_manager.config.log_level
    logging_config = get_logging_config(log_level)
    logging.config.dictConfig(logging_config)
```

## Error Handling Patterns

### Exception Hierarchy

```python
class PowerManagerError(Exception):
    """Base exception for power manager errors"""
    pass

class ConfigurationError(PowerManagerError):
    """Error related to configuration"""
    pass

class HardwareError(PowerManagerError):
    """Error related to hardware access"""
    pass

class CommunicationError(PowerManagerError):
    """Error related to inter-component communication"""
    pass

class ServiceError(PowerManagerError):
    """Error related to service operation"""
    pass
```

### Error Handling Decorators

```python
import functools
import traceback
from src.logging.logger import logger

def handle_errors(default_return=None, log_level=logging.ERROR):
    """Decorator to handle exceptions in functions"""
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            try:
                return func(*args, **kwargs)
            except Exception as e:
                logger.log(log_level, f"Error in {func.__name__}: {str(e)}")
                logger.debug(f"Traceback: {traceback.format_exc()}")
                
                # If the exception is a known power manager error, re-raise it
                if isinstance(e, PowerManagerError):
                    raise
                
                # For unexpected errors, return the default value
                return default_return
        return wrapper
    return decorator

def retry_on_failure(max_attempts=3, delay=1, exceptions=(Exception,)):
    """Decorator to retry a function on failure"""
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            last_exception = None
            
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    last_exception = e
                    logger.warning(
                        f"Attempt {attempt + 1}/{max_attempts} failed for {func.__name__}: {str(e)}"
                    )
                    
                    if attempt < max_attempts - 1:
                        import time
                        time.sleep(delay)
            
            # If all attempts failed, log the error and re-raise
            logger.error(
                f"All {max_attempts} attempts failed for {func.__name__}: {str(last_exception)}"
            )
            raise last_exception
        return wrapper
    return decorator
```

### Service-Level Error Handling

```python
import signal
import sys
from src.logging.logger import logger

class ServiceManager:
    """Manages service lifecycle with proper error handling"""
    
    def __init__(self):
        self.services = []
        self.running = False
    
    def register_service(self, service):
        """Register a service for lifecycle management"""
        self.services.append(service)
    
    def start(self):
        """Start all services with error handling"""
        logger.info("Starting power management services")
        
        try:
            # Set up signal handlers for graceful shutdown
            signal.signal(signal.SIGINT, self._signal_handler)
            signal.signal(signal.SIGTERM, self._signal_handler)
            
            # Start services
            for service in self.services:
                try:
                    service.start()
                    logger.info(f"Started service: {service.__class__.__name__}")
                except Exception as e:
                    logger.error(
                        f"Failed to start service {service.__class__.__name__}: {str(e)}"
                    )
                    raise ServiceError(f"Service startup failed: {str(e)}")
            
            self.running = True
            logger.info("All services started successfully")
            
            # Main loop
            while self.running:
                # Service monitoring and health checks could go here
                import time
                time.sleep(1)
                
        except Exception as e:
            logger.critical(f"Critical error in service manager: {str(e)}")
            self.stop()
            sys.exit(1)
    
    def stop(self):
        """Stop all services gracefully"""
        logger.info("Stopping power management services")
        
        for service in reversed(self.services):
            try:
                service.stop()
                logger.info(f"Stopped service: {service.__class__.__name__}")
            except Exception as e:
                logger.error(
                    f"Error stopping service {service.__class__.__name__}: {str(e)}"
                )
        
        self.running = False
        logger.info("All services stopped")
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        logger.info(f"Received signal {signum}, shutting down")
        self.stop()
        sys.exit(0)
```

## Integration with Components

### Monitoring Service Logging

```python
class MonitoringService:
    def __init__(self):
        self.logger = PowerManagerLogger("steamdeck.powermanager.monitoring")
    
    @handle_errors(default_return=None)
    def read_battery_data(self):
        """Read battery data with error handling"""
        try:
            # Battery reading logic
            data = self._read_from_sysfs()
            self.logger.debug(f"Battery data: {data}")
            return data
        except FileNotFoundError as e:
            self.logger.warning(f"Battery sysfs entry not found: {str(e)}")
            return None
        except PermissionError as e:
            self.logger.error(f"Permission denied reading battery data: {str(e)}")
            raise HardwareError("Insufficient permissions to read battery data")
```

### Control Service Error Handling

```python
class ControlService:
    def __init__(self):
        self.logger = PowerManagerLogger("steamdeck.powermanager.control")
    
    @retry_on_failure(max_attempts=3, delay=0.5)
    def adjust_cpu_frequency(self, target_frequency):
        """Adjust CPU frequency with retry logic"""
        try:
            # CPU frequency adjustment logic
            self._write_to_cpufreq(target_frequency)
            self.logger.info(f"CPU frequency adjusted to {target_frequency}MHz")
        except IOError as e:
            self.logger.error(f"Failed to adjust CPU frequency: {str(e)}")
            raise HardwareError(f"CPU frequency adjustment failed: {str(e)}")
```

## Log Analysis Tools

### Log Parser

```python
import json
import re
from datetime import datetime
from typing import List, Dict, Any

class LogParser:
    """Utility for parsing and analyzing log files"""
    
    def __init__(self, log_file: str):
        self.log_file = log_file
    
    def parse_json_logs(self) -> List[Dict[str, Any]]:
        """Parse JSON format logs"""
        logs = []
        with open(self.log_file, 'r') as f:
            for line in f:
                try:
                    log_entry = json.loads(line.strip())
                    logs.append(log_entry)
                except json.JSONDecodeError:
                    # Skip invalid JSON lines
                    continue
        return logs
    
    def filter_by_level(self, logs: List[Dict], level: str) -> List[Dict]:
        """Filter logs by level"""
        return [log for log in logs if log.get('level') == level]
    
    def filter_by_time_range(self, logs: List[Dict], start_time: str, end_time: str) -> List[Dict]:
        """Filter logs by time range"""
        start = datetime.fromisoformat(start_time)
        end = datetime.fromisoformat(end_time)
        
        filtered_logs = []
        for log in logs:
            timestamp = datetime.fromisoformat(log.get('timestamp', ''))
            if start <= timestamp <= end:
                filtered_logs.append(log)
        return filtered_logs
    
    def get_error_summary(self, logs: List[Dict]) -> Dict[str, int]:
        """Get summary of error types"""
        error_counts = {}
        for log in logs:
            if log.get('level') in ['ERROR', 'CRITICAL']:
                message = log.get('message', '')
                # Extract error type from message
                error_type = message.split(':')[0] if ':' in message else 'Unknown'
                error_counts[error_type] = error_counts.get(error_type, 0) + 1
        return error_counts
```

## Monitoring and Alerting

### Health Check System

```python
import time
from typing import Dict, Any

class HealthMonitor:
    """Monitor system health and send alerts"""
    
    def __init__(self):
        self.logger = PowerManagerLogger("steamdeck.powermanager.health")
        self.last_alert_times = {}
    
    def check_service_health(self, service_name: str, status: Dict[str, Any]) -> bool:
        """Check if a service is healthy"""
        healthy = status.get('healthy', False)
        
        if not healthy:
            # Check if we should send an alert (rate limiting)
            last_alert = self.last_alert_times.get(service_name, 0)
            current_time = time.time()
            
            # Only alert every 5 minutes for the same issue
            if current_time - last_alert > 300:
                self.logger.critical(f"Service {service_name} is unhealthy: {status.get('message', 'Unknown error')}")
                self._send_alert(f"Service {service_name} failure", status.get('message', 'Unknown error'))
                self.last_alert_times[service_name] = current_time
        
        return healthy
    
    def _send_alert(self, title: str, message: str):
        """Send an alert (could be email, notification, etc.)"""
        # For now, just log the alert
        self.logger.critical(f"ALERT: {title} - {message}")
        
        # In a real implementation, this could:
        # - Send email notifications
        # - Send desktop notifications
        # - Log to external monitoring systems
        # - Trigger automated recovery actions
```

## Performance Considerations

### Asynchronous Logging

To prevent logging from blocking critical operations:

```python
import threading
import queue
from src.logging.logger import logger

class AsyncLogger:
    """Asynchronous logger wrapper"""
    
    def __init__(self):
        self.log_queue = queue.Queue(maxsize=1000)
        self.worker_thread = threading.Thread(target=self._process_logs, daemon=True)
        self.worker_thread.start()
    
    def _process_logs(self):
        while True:
            try:
                level, message = self.log_queue.get(timeout=1)
                if level == 'debug':
                    logger.debug(message)
                elif level == 'info':
                    logger.info(message)
                elif level == 'warning':
                    logger.warning(message)
                elif level == 'error':
                    logger.error(message)
                elif level == 'critical':
                    logger.critical(message)
                self.log_queue.task_done()
            except queue.Empty:
                continue
    
    def info(self, message: str):
        try:
            self.log_queue.put_nowait(('info', message))
        except queue.Full:
            # Drop the log message if queue is full
            pass
```

## Security Considerations

### Log Sanitization

```python
import re

class LogSanitizer:
    """Sanitize sensitive information from logs"""
    
    SENSITIVE_PATTERNS = [
        (re.compile(r'password[=\s]*["\']?([^"\']*)["\']?'), 'password=[REDACTED]'),
        (re.compile(r'key[=\s]*["\']?([^"\']*)["\']?'), 'key=[REDACTED]'),
        (re.compile(r'token[=\s]*["\']?([^"\']*)["\']?'), 'token=[REDACTED]'),
    ]
    
    @classmethod
    def sanitize_message(cls, message: str) -> str:
        """Remove sensitive information from log messages"""
        sanitized = message
        for pattern, replacement in cls.SENSITIVE_PATTERNS:
            sanitized = pattern.sub(replacement, sanitized)
        return sanitized
```

This logging and error handling system provides:

1. Multi-level logging with different handlers
2. Structured logging in JSON format
3. Asynchronous logging to prevent blocking
4. Rate limiting to prevent log flooding
5. Comprehensive error handling patterns
6. Service lifecycle management
7. Log analysis tools
8. Health monitoring and alerting
9. Security considerations for sensitive data