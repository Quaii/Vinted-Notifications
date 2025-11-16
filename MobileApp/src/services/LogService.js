/**
 * LogService
 * Logging service matching desktop app pattern with levels
 * Supports INFO, WARNING, ERROR levels with color coding
 */
class LogService {
  constructor() {
    this.logs = [];
    this.MAX_LOGS = 500; // Keep last 500 logs
    this.listeners = [];
  }

  /**
   * Log levels matching desktop app
   */
  LEVELS = {
    INFO: 'INFO',
    WARNING: 'WARNING',
    ERROR: 'ERROR',
  };

  /**
   * Add a log entry with level
   */
  _addLog(level, message) {
    const entry = {
      id: Date.now() + Math.random(),
      timestamp: new Date().toISOString(),
      level,
      message,
    };

    // Add to beginning (newest first)
    this.logs.unshift(entry);

    // Trim to max size
    if (this.logs.length > this.MAX_LOGS) {
      this.logs = this.logs.slice(0, this.MAX_LOGS);
    }

    // Notify listeners
    this.notifyListeners();

    // Also log to console
    const time = new Date().toLocaleTimeString();
    console.log(`[${time}] ${level} - ${message}`);

    return entry;
  }

  /**
   * Log info message (default level)
   */
  info(message) {
    return this._addLog(this.LEVELS.INFO, message);
  }

  /**
   * Log warning message
   */
  warning(message) {
    return this._addLog(this.LEVELS.WARNING, message);
  }

  /**
   * Log error message
   */
  error(message) {
    return this._addLog(this.LEVELS.ERROR, message);
  }

  /**
   * Generic log (defaults to INFO for backwards compatibility)
   */
  log(message) {
    return this.info(message);
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
}

// Export singleton instance
export default new LogService();
