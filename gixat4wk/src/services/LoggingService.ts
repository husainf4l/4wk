import { LogEntry, AnalyticsEvent } from '../types/api';

export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

export interface LoggingConfig {
  enableConsoleLogging: boolean;
  enableRemoteLogging: boolean;
  logLevel: LogLevel;
  maxLogEntries: number;
  enableAnalytics: boolean;
}

class LoggingService {
  private config: LoggingConfig = {
    enableConsoleLogging: __DEV__,
    enableRemoteLogging: !__DEV__,
    logLevel: __DEV__ ? 'debug' : 'info',
    maxLogEntries: 1000,
    enableAnalytics: true,
  };

  private logs: LogEntry[] = [];
  private sessionId: string = this.generateSessionId();

  constructor() {
    this.setupGlobalErrorHandler();
  }

  private generateSessionId(): string {
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private setupGlobalErrorHandler() {
    // Handle JavaScript errors
    const originalHandler = ErrorUtils.getGlobalHandler();
    ErrorUtils.setGlobalHandler((error, isFatal) => {
      this.error('Global JavaScript Error', {
        message: error.message,
        stack: error.stack,
        isFatal,
        name: error.name,
      });

      if (originalHandler) {
        originalHandler(error, isFatal);
      }
    });

    // Handle unhandled promise rejections
    const originalRejectionHandler = global.onunhandledrejection;
    global.onunhandledrejection = (event) => {
      this.error('Unhandled Promise Rejection', {
        reason: event.reason,
        promise: event.promise?.toString(),
      });

      if (originalRejectionHandler) {
        originalRejectionHandler(event);
      }
    };
  }

  private shouldLog(level: LogLevel): boolean {
    const levels: Record<LogLevel, number> = {
      debug: 0,
      info: 1,
      warn: 2,
      error: 3,
    };

    return levels[level] >= levels[this.config.logLevel];
  }

  private createLogEntry(
    level: LogLevel,
    message: string,
    context?: Record<string, any>,
    userId?: string
  ): LogEntry {
    return {
      level,
      message,
      timestamp: new Date(),
      context,
      userId,
      sessionId: this.sessionId,
    };
  }

  private addLog(entry: LogEntry) {
    this.logs.push(entry);

    // Remove old logs if we exceed the limit
    if (this.logs.length > this.config.maxLogEntries) {
      this.logs.splice(0, this.logs.length - this.config.maxLogEntries);
    }

    // Console logging
    if (this.config.enableConsoleLogging) {
      const logMethod = console[entry.level] || console.log;
      logMethod(`[${entry.level.toUpperCase()}] ${entry.message}`, entry.context || '');
    }

    // Remote logging (implement based on your logging service)
    if (this.config.enableRemoteLogging) {
      this.sendToRemoteLogger(entry);
    }
  }

  private async sendToRemoteLogger(entry: LogEntry) {
    try {
      // Implement your remote logging service here
      // Example: Firebase Analytics, Crashlytics, or custom API
      console.log('Would send to remote logger:', entry);
    } catch (error) {
      console.error('Failed to send log to remote service:', error);
    }
  }

  // Public logging methods
  debug(message: string, context?: Record<string, any>, userId?: string) {
    if (this.shouldLog('debug')) {
      const entry = this.createLogEntry('debug', message, context, userId);
      this.addLog(entry);
    }
  }

  info(message: string, context?: Record<string, any>, userId?: string) {
    if (this.shouldLog('info')) {
      const entry = this.createLogEntry('info', message, context, userId);
      this.addLog(entry);
    }
  }

  warn(message: string, context?: Record<string, any>, userId?: string) {
    if (this.shouldLog('warn')) {
      const entry = this.createLogEntry('warn', message, context, userId);
      this.addLog(entry);
    }
  }

  error(message: string, context?: Record<string, any>, userId?: string) {
    if (this.shouldLog('error')) {
      const entry = this.createLogEntry('error', message, context, userId);
      this.addLog(entry);
    }
  }

  // Performance logging
  time(label: string) {
    console.time(label);
  }

  timeEnd(label: string, context?: Record<string, any>, userId?: string) {
    console.timeEnd(label);
    this.info(`Performance: ${label}`, context, userId);
  }

  // API request logging
  logApiRequest(
    method: string,
    url: string,
    status: number,
    duration: number,
    userId?: string
  ) {
    const level = status >= 400 ? 'error' : status >= 300 ? 'warn' : 'info';
    this[level]('API Request', {
      method,
      url,
      status,
      duration,
    }, userId);
  }

  // User action logging
  logUserAction(
    action: string,
    screen: string,
    context?: Record<string, any>,
    userId?: string
  ) {
    this.info('User Action', {
      action,
      screen,
      ...context,
    }, userId);
  }

  // Navigation logging
  logNavigation(
    from: string,
    to: string,
    params?: Record<string, any>,
    userId?: string
  ) {
    this.info('Navigation', {
      from,
      to,
      params,
    }, userId);
  }

  // Business logic logging
  logBusinessEvent(
    event: string,
    entityType: string,
    entityId: string,
    context?: Record<string, any>,
    userId?: string
  ) {
    this.info('Business Event', {
      event,
      entityType,
      entityId,
      ...context,
    }, userId);
  }

  // Analytics
  trackEvent(event: AnalyticsEvent) {
    if (!this.config.enableAnalytics) return;

    this.info('Analytics Event', {
      name: event.name,
      properties: event.properties,
    }, event.userId);

    // Send to analytics service (Firebase Analytics, etc.)
    this.sendToAnalytics(event);
  }

  private async sendToAnalytics(event: AnalyticsEvent) {
    try {
      // Implement your analytics service here
      // Example: Firebase Analytics
      console.log('Would send to analytics:', event);
    } catch (error) {
      this.error('Failed to send analytics event', { error: error.message });
    }
  }

  // Configuration
  updateConfig(newConfig: Partial<LoggingConfig>) {
    this.config = { ...this.config, ...newConfig };
  }

  getConfig(): LoggingConfig {
    return { ...this.config };
  }

  // Log retrieval
  getLogs(level?: LogLevel, limit?: number): LogEntry[] {
    let filteredLogs = this.logs;

    if (level) {
      filteredLogs = this.logs.filter(log => log.level === level);
    }

    if (limit) {
      return filteredLogs.slice(-limit);
    }

    return filteredLogs;
  }

  clearLogs() {
    this.logs = [];
  }

  // Session management
  getSessionId(): string {
    return this.sessionId;
  }

  startNewSession() {
    this.sessionId = this.generateSessionId();
    this.info('New session started', { sessionId: this.sessionId });
  }

  // Export logs for debugging
  exportLogs(): string {
    return JSON.stringify(this.logs, null, 2);
  }
}

export const loggingService = new LoggingService();