/**
 * LogService
 * Centralized logging service for tracking application events
 */
class LogService {
  constructor() {
    this.logs = [];
    this.MAX_LOGS = 1000; // Keep last 1000 logs
    this.listeners = [];
  }

  /**
   * Log levels
   */
  LEVELS = {
    INFO: 'info',
    SUCCESS: 'success',
    WARNING: 'warning',
    ERROR: 'error',
    DEBUG: 'debug',
  };

  /**
   * Add a log entry
   */
  log(level, message, data = null) {
    const entry = {
      id: Date.now() + Math.random(),
      timestamp: new Date().toISOString(),
      level,
      message,
      data,
    };

    // Add to beginning of array (newest first)
    this.logs.unshift(entry);

    // Trim to max size
    if (this.logs.length > this.MAX_LOGS) {
      this.logs = this.logs.slice(0, this.MAX_LOGS);
    }

    // Notify listeners
    this.notifyListeners();

    // Also log to console
    const timestamp = new Date().toLocaleTimeString();
    const logMessage = `[${timestamp}] [${level.toUpperCase()}] ${message}`;

    switch (level) {
      case this.LEVELS.ERROR:
        console.error(logMessage, data || '');
        break;
      case this.LEVELS.WARNING:
        console.warn(logMessage, data || '');
        break;
      case this.LEVELS.DEBUG:
        console.debug(logMessage, data || '');
        break;
      default:
        console.log(logMessage, data || '');
    }

    return entry;
  }

  /**
   * Convenience methods
   */
  info(message, data) {
    return this.log(this.LEVELS.INFO, message, data);
  }

  success(message, data) {
    return this.log(this.LEVELS.SUCCESS, message, data);
  }

  warning(message, data) {
    return this.log(this.LEVELS.WARNING, message, data);
  }

  error(message, data) {
    return this.log(this.LEVELS.ERROR, message, data);
  }

  debug(message, data) {
    return this.log(this.LEVELS.DEBUG, message, data);
  }

  /**
   * Get all logs
   */
  getLogs(limit = null) {
    if (limit) {
      return this.logs.slice(0, limit);
    }
    return [...this.logs];
  }

  /**
   * Get logs by level
   */
  getLogsByLevel(level, limit = null) {
    const filtered = this.logs.filter(log => log.level === level);
    if (limit) {
      return filtered.slice(0, limit);
    }
    return filtered;
  }

  /**
   * Get logs from last N minutes
   */
  getRecentLogs(minutes = 5, limit = null) {
    const cutoff = Date.now() - minutes * 60 * 1000;
    const filtered = this.logs.filter(log => {
      return new Date(log.timestamp).getTime() >= cutoff;
    });
    if (limit) {
      return filtered.slice(0, limit);
    }
    return filtered;
  }

  /**
   * Clear all logs
   */
  clearLogs() {
    this.logs = [];
    this.notifyListeners();
  }

  /**
   * Subscribe to log updates
   */
  subscribe(listener) {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter(l => l !== listener);
    };
  }

  /**
   * Notify all listeners
   */
  notifyListeners() {
    this.listeners.forEach(listener => {
      try {
        listener(this.logs);
      } catch (error) {
        console.error('Error notifying log listener:', error);
      }
    });
  }

  /**
   * Get log stats
   */
  getStats() {
    const stats = {
      total: this.logs.length,
      info: 0,
      success: 0,
      warning: 0,
      error: 0,
      debug: 0,
    };

    this.logs.forEach(log => {
      if (stats.hasOwnProperty(log.level)) {
        stats[log.level]++;
      }
    });

    return stats;
  }
}

// Export singleton instance
export default new LogService();
