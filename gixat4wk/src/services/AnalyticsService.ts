import { AnalyticsEvent } from '../types/api';
import { loggingService } from './LoggingService';

export interface UserProperties {
  userId: string;
  role: string;
  garageId?: string;
  firstName?: string;
  lastName?: string;
  email?: string;
  registrationDate?: Date;
}

export interface SessionProperties {
  sessionId: string;
  startTime: Date;
  appVersion: string;
  platform: string;
  deviceModel?: string;
}

class AnalyticsService {
  private isEnabled: boolean = true;
  private userId?: string;
  private userProperties: Partial<UserProperties> = {};
  private sessionProperties: SessionProperties;

  constructor() {
    this.sessionProperties = {
      sessionId: loggingService.getSessionId(),
      startTime: new Date(),
      appVersion: '1.0.0',
      platform: 'react-native',
    };

    this.trackEvent('app_session_start', this.sessionProperties);
  }

  // Configuration
  setEnabled(enabled: boolean) {
    this.isEnabled = enabled;
    loggingService.updateConfig({ enableAnalytics: enabled });
  }

  isAnalyticsEnabled(): boolean {
    return this.isEnabled;
  }

  // User identification
  setUserId(userId: string) {
    this.userId = userId;
    this.trackEvent('user_identified', { userId });
  }

  setUserProperties(properties: Partial<UserProperties>) {
    this.userProperties = { ...this.userProperties, ...properties };
    this.trackEvent('user_properties_updated', properties);
  }

  getUserId(): string | undefined {
    return this.userId;
  }

  // Event tracking
  trackEvent(eventName: string, properties?: Record<string, any>) {
    if (!this.isEnabled) return;

    const event: AnalyticsEvent = {
      name: eventName,
      properties: {
        ...properties,
        ...this.sessionProperties,
        userId: this.userId,
        timestamp: new Date().toISOString(),
      },
      timestamp: new Date(),
      userId: this.userId,
      sessionId: this.sessionProperties.sessionId,
    };

    loggingService.trackEvent(event);
  }

  // Screen tracking
  trackScreenView(screenName: string, properties?: Record<string, any>) {
    this.trackEvent('screen_view', {
      screen_name: screenName,
      ...properties,
    });
  }

  // Business events
  trackCustomerCreated(customerId: string, isCompany: boolean) {
    this.trackEvent('customer_created', {
      customer_id: customerId,
      is_company: isCompany,
    });
  }

  trackCarAdded(carId: string, customerId: string, make: string, model: string) {
    this.trackEvent('car_added', {
      car_id: carId,
      customer_id: customerId,
      make,
      model,
    });
  }

  trackSessionCreated(sessionId: string, customerId: string, carId: string, requestCount: number) {
    this.trackEvent('session_created', {
      session_id: sessionId,
      customer_id: customerId,
      car_id: carId,
      request_count: requestCount,
    });
  }

  trackInspectionStarted(sessionId: string, inspectionType: string) {
    this.trackEvent('inspection_started', {
      session_id: sessionId,
      inspection_type: inspectionType,
    });
  }

  trackInspectionCompleted(sessionId: string, findingsCount: number, imagesCount: number) {
    this.trackEvent('inspection_completed', {
      session_id: sessionId,
      findings_count: findingsCount,
      images_count: imagesCount,
    });
  }

  trackTestDriveStarted(sessionId: string) {
    this.trackEvent('test_drive_started', {
      session_id: sessionId,
    });
  }

  trackTestDriveCompleted(sessionId: string, duration: number, mileageDriven: number) {
    this.trackEvent('test_drive_completed', {
      session_id: sessionId,
      duration_minutes: duration,
      mileage_driven: mileageDriven,
    });
  }

  trackReportGenerated(sessionId: string, reportType: string) {
    this.trackEvent('report_generated', {
      session_id: sessionId,
      report_type: reportType,
    });
  }

  trackReportShared(sessionId: string, shareMethod: string) {
    this.trackEvent('report_shared', {
      session_id: sessionId,
      share_method: shareMethod,
    });
  }

  trackJobOrderCreated(jobOrderId: string, sessionId: string, totalAmount: number) {
    this.trackEvent('job_order_created', {
      job_order_id: jobOrderId,
      session_id: sessionId,
      total_amount: totalAmount,
    });
  }

  // User interaction events
  trackButtonClick(buttonName: string, screen: string, context?: Record<string, any>) {
    this.trackEvent('button_click', {
      button_name: buttonName,
      screen,
      ...context,
    });
  }

  trackFormSubmitted(formName: string, screen: string, success: boolean) {
    this.trackEvent('form_submitted', {
      form_name: formName,
      screen,
      success,
    });
  }

  trackSearchPerformed(query: string, screen: string, resultCount: number) {
    this.trackEvent('search_performed', {
      query,
      screen,
      result_count: resultCount,
    });
  }

  trackFileUploaded(fileType: string, fileSize: number, uploadTime: number) {
    this.trackEvent('file_uploaded', {
      file_type: fileType,
      file_size_bytes: fileSize,
      upload_time_ms: uploadTime,
    });
  }

  // Error tracking
  trackError(errorType: string, errorMessage: string, screen?: string, context?: Record<string, any>) {
    this.trackEvent('error_occurred', {
      error_type: errorType,
      error_message: errorMessage,
      screen,
      ...context,
    });
  }

  trackApiError(endpoint: string, method: string, statusCode: number, errorMessage: string) {
    this.trackEvent('api_error', {
      endpoint,
      method,
      status_code: statusCode,
      error_message: errorMessage,
    });
  }

  // Performance tracking
  trackPerformance(operationName: string, duration: number, context?: Record<string, any>) {
    this.trackEvent('performance_measured', {
      operation_name: operationName,
      duration_ms: duration,
      ...context,
    });
  }

  trackAppLaunch(launchTime: number, isFirstLaunch: boolean) {
    this.trackEvent('app_launched', {
      launch_time_ms: launchTime,
      is_first_launch: isFirstLaunch,
    });
  }

  // Feature usage
  trackFeatureUsed(featureName: string, context?: Record<string, any>) {
    this.trackEvent('feature_used', {
      feature_name: featureName,
      ...context,
    });
  }

  trackSettingChanged(settingName: string, oldValue: any, newValue: any) {
    this.trackEvent('setting_changed', {
      setting_name: settingName,
      old_value: oldValue,
      new_value: newValue,
    });
  }

  // Custom events for specific workflows
  trackWorkflowStarted(workflowName: string, context?: Record<string, any>) {
    this.trackEvent('workflow_started', {
      workflow_name: workflowName,
      ...context,
    });
  }

  trackWorkflowCompleted(workflowName: string, duration: number, context?: Record<string, any>) {
    this.trackEvent('workflow_completed', {
      workflow_name: workflowName,
      duration_ms: duration,
      ...context,
    });
  }

  trackWorkflowAbandoned(workflowName: string, step: string, context?: Record<string, any>) {
    this.trackEvent('workflow_abandoned', {
      workflow_name: workflowName,
      abandoned_at_step: step,
      ...context,
    });
  }

  // Session management
  startNewSession() {
    this.sessionProperties = {
      sessionId: loggingService.getSessionId(),
      startTime: new Date(),
      appVersion: this.sessionProperties.appVersion,
      platform: this.sessionProperties.platform,
      deviceModel: this.sessionProperties.deviceModel,
    };

    this.trackEvent('app_session_start', this.sessionProperties);
  }

  endSession() {
    const sessionDuration = Date.now() - this.sessionProperties.startTime.getTime();
    this.trackEvent('app_session_end', {
      session_duration_ms: sessionDuration,
    });
  }

  // Utility methods
  flush() {
    // Force send any pending analytics events
    this.trackEvent('analytics_flush_requested');
  }

  reset() {
    this.userId = undefined;
    this.userProperties = {};
    this.trackEvent('analytics_reset');
  }
}

export const analyticsService = new AnalyticsService();