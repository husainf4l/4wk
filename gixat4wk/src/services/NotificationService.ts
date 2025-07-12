import { Platform } from 'react-native';
import PushNotification from 'react-native-push-notification';
import { NotificationPayload, PushNotificationConfig } from '../types/api';
import { loggingService } from './LoggingService';
import { analyticsService } from './AnalyticsService';
import { persistenceService } from './PersistenceService';

export interface LocalNotification {
  id: string;
  title: string;
  message: string;
  data?: any;
  scheduledDate?: Date;
  repeatType?: 'minute' | 'hour' | 'day' | 'week' | 'month' | 'year';
  soundName?: string;
  badge?: number;
  category?: string;
  userInfo?: any;
}

export interface NotificationAction {
  id: string;
  title: string;
  type: 'foreground' | 'background' | 'destructive';
  authenticationRequired?: boolean;
}

export interface NotificationCategory {
  id: string;
  actions: NotificationAction[];
}

export interface NotificationSettings {
  enabled: boolean;
  sound: boolean;
  vibration: boolean;
  badge: boolean;
  categories: {
    sessions: boolean;
    inspections: boolean;
    reports: boolean;
    reminders: boolean;
    system: boolean;
  };
}

class NotificationService {
  private isInitialized = false;
  private pushToken: string | null = null;
  private settings: NotificationSettings = {
    enabled: true,
    sound: true,
    vibration: true,
    badge: true,
    categories: {
      sessions: true,
      inspections: true,
      reports: true,
      reminders: true,
      system: true,
    },
  };

  async initialize(): Promise<void> {
    if (this.isInitialized) return;

    try {
      // Load settings
      await this.loadSettings();

      // Configure push notifications
      PushNotification.configure({
        onRegister: (token) => {
          this.pushToken = token.token;
          loggingService.info('Push notification token received', { token: token.token });
          analyticsService.trackEvent('push_token_received', { platform: Platform.OS });
        },

        onNotification: (notification) => {
          this.handleNotification(notification);
        },

        onAction: (notification) => {
          this.handleNotificationAction(notification);
        },

        onRegistrationError: (err) => {
          loggingService.error('Push notification registration failed', { error: err.message });
          analyticsService.trackError('push_registration_error', err.message);
        },

        permissions: {
          alert: true,
          badge: true,
          sound: true,
        },

        popInitialNotification: true,
        requestPermissions: Platform.OS === 'ios',
      });

      // Create notification categories
      this.createNotificationCategories();

      this.isInitialized = true;
      loggingService.info('Notification service initialized');
    } catch (error) {
      loggingService.error('Failed to initialize notification service', { 
        error: error.message 
      });
      throw error;
    }
  }

  private async loadSettings(): Promise<void> {
    try {
      const stored = await persistenceService.retrieve<NotificationSettings>('notification_settings');
      if (stored) {
        this.settings = { ...this.settings, ...stored };
      }
    } catch (error) {
      loggingService.warn('Failed to load notification settings', { error: error.message });
    }
  }

  private async saveSettings(): Promise<void> {
    try {
      await persistenceService.store('notification_settings', this.settings);
    } catch (error) {
      loggingService.error('Failed to save notification settings', { error: error.message });
    }
  }

  private createNotificationCategories(): void {
    const categories: NotificationCategory[] = [
      {
        id: 'SESSION_ACTIONS',
        actions: [
          {
            id: 'VIEW_SESSION',
            title: 'View Session',
            type: 'foreground',
          },
          {
            id: 'START_INSPECTION',
            title: 'Start Inspection',
            type: 'foreground',
          },
        ],
      },
      {
        id: 'INSPECTION_ACTIONS',
        actions: [
          {
            id: 'CONTINUE_INSPECTION',
            title: 'Continue',
            type: 'foreground',
          },
          {
            id: 'COMPLETE_INSPECTION',
            title: 'Complete',
            type: 'foreground',
          },
        ],
      },
      {
        id: 'REPORT_ACTIONS',
        actions: [
          {
            id: 'VIEW_REPORT',
            title: 'View Report',
            type: 'foreground',
          },
          {
            id: 'SHARE_REPORT',
            title: 'Share',
            type: 'foreground',
          },
        ],
      },
    ];

    // Register categories with the system
    categories.forEach(category => {
      if (Platform.OS === 'ios') {
        // iOS category registration would go here
        // This requires native iOS implementation
      }
    });
  }

  private handleNotification(notification: any): void {
    loggingService.info('Notification received', { 
      title: notification.title,
      message: notification.message,
      data: notification.data,
      foreground: notification.foreground,
    });

    analyticsService.trackEvent('notification_received', {
      title: notification.title,
      category: notification.data?.category,
      foreground: notification.foreground,
    });

    // Handle foreground notifications
    if (notification.foreground && this.settings.enabled) {
      this.showInAppNotification(notification);
    }

    // Execute notification finish callback
    if (notification.finish) {
      notification.finish('UNNotificationPresentationOptionAlert');
    }
  }

  private handleNotificationAction(notification: any): void {
    const action = notification.action;
    const data = notification.data || {};

    loggingService.info('Notification action taken', { 
      action,
      data,
      title: notification.title 
    });

    analyticsService.trackEvent('notification_action', {
      action,
      notification_title: notification.title,
      category: data.category,
    });

    // Handle specific actions
    switch (action) {
      case 'VIEW_SESSION':
        this.navigateToSession(data.sessionId);
        break;
      case 'START_INSPECTION':
        this.navigateToInspection(data.sessionId);
        break;
      case 'CONTINUE_INSPECTION':
        this.navigateToInspection(data.inspectionId);
        break;
      case 'VIEW_REPORT':
        this.navigateToReport(data.sessionId);
        break;
      default:
        // Handle unknown actions
        break;
    }
  }

  private showInAppNotification(notification: any): void {
    // This would show an in-app notification banner
    // Implementation depends on your UI framework
    loggingService.debug('Showing in-app notification', { 
      title: notification.title,
      message: notification.message 
    });
  }

  private navigateToSession(sessionId: string): void {
    // Navigation logic would go here
    loggingService.info('Navigating to session from notification', { sessionId });
  }

  private navigateToInspection(sessionId: string): void {
    // Navigation logic would go here
    loggingService.info('Navigating to inspection from notification', { sessionId });
  }

  private navigateToReport(sessionId: string): void {
    // Navigation logic would go here
    loggingService.info('Navigating to report from notification', { sessionId });
  }

  // Permission management
  async requestPermissions(): Promise<boolean> {
    try {
      const permissions = await PushNotification.requestPermissions();
      const granted = permissions.alert && permissions.badge && permissions.sound;
      
      loggingService.info('Notification permissions requested', { 
        granted,
        permissions 
      });
      
      analyticsService.trackEvent('notification_permissions_requested', {
        granted,
        alert: permissions.alert,
        badge: permissions.badge,
        sound: permissions.sound,
      });

      return granted;
    } catch (error) {
      loggingService.error('Failed to request notification permissions', { 
        error: error.message 
      });
      return false;
    }
  }

  async checkPermissions(): Promise<{
    alert: boolean;
    badge: boolean;
    sound: boolean;
  }> {
    return new Promise((resolve) => {
      PushNotification.checkPermissions((permissions) => {
        resolve(permissions);
      });
    });
  }

  // Local notifications
  async scheduleLocalNotification(notification: LocalNotification): Promise<void> {
    if (!this.settings.enabled) {
      loggingService.debug('Notifications disabled, skipping local notification');
      return;
    }

    try {
      const notificationConfig: any = {
        id: notification.id,
        title: notification.title,
        message: notification.message,
        playSound: this.settings.sound,
        vibrate: this.settings.vibration,
        badge: notification.badge || 0,
        category: notification.category,
        userInfo: notification.data || {},
      };

      if (notification.scheduledDate) {
        notificationConfig.date = notification.scheduledDate;
      }

      if (notification.repeatType) {
        notificationConfig.repeatType = notification.repeatType;
      }

      if (notification.soundName && this.settings.sound) {
        notificationConfig.soundName = notification.soundName;
      }

      PushNotification.localNotification(notificationConfig);

      loggingService.info('Local notification scheduled', { 
        id: notification.id,
        title: notification.title,
        scheduledDate: notification.scheduledDate,
      });

      analyticsService.trackEvent('local_notification_scheduled', {
        category: notification.category,
        scheduled: !!notification.scheduledDate,
        repeat: notification.repeatType,
      });
    } catch (error) {
      loggingService.error('Failed to schedule local notification', { 
        error: error.message,
        notificationId: notification.id,
      });
    }
  }

  cancelLocalNotification(id: string): void {
    try {
      PushNotification.cancelLocalNotifications({ id });
      loggingService.info('Local notification cancelled', { id });
    } catch (error) {
      loggingService.error('Failed to cancel local notification', { 
        error: error.message,
        id,
      });
    }
  }

  cancelAllLocalNotifications(): void {
    try {
      PushNotification.cancelAllLocalNotifications();
      loggingService.info('All local notifications cancelled');
    } catch (error) {
      loggingService.error('Failed to cancel all local notifications', { 
        error: error.message 
      });
    }
  }

  // Business-specific notifications
  async notifySessionCreated(sessionId: string, customerName: string): Promise<void> {
    if (!this.settings.categories.sessions) return;

    await this.scheduleLocalNotification({
      id: `session_created_${sessionId}`,
      title: 'New Session Created',
      message: `Session created for ${customerName}`,
      category: 'SESSION_ACTIONS',
      data: { sessionId, type: 'session_created' },
    });
  }

  async notifyInspectionDue(sessionId: string, customerName: string): Promise<void> {
    if (!this.settings.categories.inspections) return;

    await this.scheduleLocalNotification({
      id: `inspection_due_${sessionId}`,
      title: 'Inspection Due',
      message: `Vehicle inspection needed for ${customerName}`,
      category: 'INSPECTION_ACTIONS',
      data: { sessionId, type: 'inspection_due' },
    });
  }

  async notifyInspectionCompleted(sessionId: string, customerName: string): Promise<void> {
    if (!this.settings.categories.inspections) return;

    await this.scheduleLocalNotification({
      id: `inspection_completed_${sessionId}`,
      title: 'Inspection Completed',
      message: `Inspection completed for ${customerName}`,
      category: 'REPORT_ACTIONS',
      data: { sessionId, type: 'inspection_completed' },
    });
  }

  async notifyReportReady(sessionId: string, customerName: string): Promise<void> {
    if (!this.settings.categories.reports) return;

    await this.scheduleLocalNotification({
      id: `report_ready_${sessionId}`,
      title: 'Report Ready',
      message: `Inspection report ready for ${customerName}`,
      category: 'REPORT_ACTIONS',
      data: { sessionId, type: 'report_ready' },
    });
  }

  async scheduleSessionReminder(
    sessionId: string,
    customerName: string,
    scheduledTime: Date
  ): Promise<void> {
    if (!this.settings.categories.reminders) return;

    // Schedule reminder 30 minutes before
    const reminderTime = new Date(scheduledTime.getTime() - 30 * 60 * 1000);

    await this.scheduleLocalNotification({
      id: `session_reminder_${sessionId}`,
      title: 'Upcoming Session',
      message: `Session with ${customerName} in 30 minutes`,
      scheduledDate: reminderTime,
      category: 'SESSION_ACTIONS',
      data: { sessionId, type: 'session_reminder' },
    });
  }

  async scheduleServiceReminder(
    carId: string,
    customerName: string,
    make: string,
    model: string,
    serviceDate: Date
  ): Promise<void> {
    if (!this.settings.categories.reminders) return;

    // Schedule reminder 7 days before
    const reminderTime = new Date(serviceDate.getTime() - 7 * 24 * 60 * 60 * 1000);

    await this.scheduleLocalNotification({
      id: `service_reminder_${carId}`,
      title: 'Service Reminder',
      message: `${make} ${model} service due in 7 days for ${customerName}`,
      scheduledDate: reminderTime,
      data: { carId, type: 'service_reminder' },
    });
  }

  // Settings management
  async updateSettings(newSettings: Partial<NotificationSettings>): Promise<void> {
    this.settings = { ...this.settings, ...newSettings };
    await this.saveSettings();
    
    loggingService.info('Notification settings updated', newSettings);
    analyticsService.trackEvent('notification_settings_changed', newSettings);
  }

  getSettings(): NotificationSettings {
    return { ...this.settings };
  }

  // Push token management
  getPushToken(): string | null {
    return this.pushToken;
  }

  async registerPushToken(userId: string): Promise<void> {
    if (!this.pushToken) {
      loggingService.warn('No push token available for registration');
      return;
    }

    try {
      // This would register the token with your backend
      // For now, we'll just log it
      loggingService.info('Push token registered', { 
        userId,
        token: this.pushToken,
        platform: Platform.OS,
      });

      analyticsService.trackEvent('push_token_registered', {
        platform: Platform.OS,
      });
    } catch (error) {
      loggingService.error('Failed to register push token', { 
        error: error.message,
        userId,
      });
    }
  }

  // Badge management
  updateBadgeCount(count: number): void {
    if (!this.settings.badge) return;

    try {
      PushNotification.setApplicationIconBadgeNumber(count);
      loggingService.debug('Badge count updated', { count });
    } catch (error) {
      loggingService.error('Failed to update badge count', { 
        error: error.message,
        count,
      });
    }
  }

  clearBadge(): void {
    this.updateBadgeCount(0);
  }

  // Cleanup
  cleanup(): void {
    this.cancelAllLocalNotifications();
    this.clearBadge();
    loggingService.info('Notification service cleaned up');
  }
}

export const notificationService = new NotificationService();