/**
 * LogService
 * Simple logging service matching desktop app pattern
 * Tracks basic app events like "Monitoring started", "Found 5 new items", etc.
 */
class LogService {
  constructor() {
    this.logs = [];
    this.MAX_LOGS = 500; // Keep last 500 logs
    this.listeners = [];
  }

  /**
   * Add a log entry (simple message only)
   */
  log(message) {
    const entry = {
      id: Date.now() + Math.random(),
      timestamp: new Date().toISOString(),
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
    console.log(`[${time}] ${message}`);

    return entry;
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
