import { useCallback } from 'react';
import { loggingService, LogLevel } from '../services/LoggingService';
import { analyticsService } from '../services/AnalyticsService';
import { useAppState } from '../context/AppStateContext';

export const useLogging = () => {
  const { state } = useAppState();
  const userId = state.user?.id;

  // Logging methods
  const logDebug = useCallback((message: string, context?: Record<string, any>) => {
    loggingService.debug(message, context, userId);
  }, [userId]);

  const logInfo = useCallback((message: string, context?: Record<string, any>) => {
    loggingService.info(message, context, userId);
  }, [userId]);

  const logWarn = useCallback((message: string, context?: Record<string, any>) => {
    loggingService.warn(message, context, userId);
  }, [userId]);

  const logError = useCallback((message: string, context?: Record<string, any>) => {
    loggingService.error(message, context, userId);
  }, [userId]);

  // Performance logging
  const logPerformance = useCallback((operationName: string, duration: number, context?: Record<string, any>) => {
    loggingService.info(`Performance: ${operationName}`, {
      duration_ms: duration,
      ...context,
    }, userId);
    
    analyticsService.trackPerformance(operationName, duration, context);
  }, [userId]);

  // User action logging
  const logUserAction = useCallback((action: string, screen: string, context?: Record<string, any>) => {
    loggingService.logUserAction(action, screen, context, userId);
    analyticsService.trackButtonClick(action, screen, context);
  }, [userId]);

  // Navigation logging
  const logNavigation = useCallback((from: string, to: string, params?: Record<string, any>) => {
    loggingService.logNavigation(from, to, params, userId);
    analyticsService.trackScreenView(to, { previous_screen: from, ...params });
  }, [userId]);

  // API logging
  const logApiRequest = useCallback((method: string, url: string, status: number, duration: number) => {
    loggingService.logApiRequest(method, url, status, duration, userId);
    
    if (status >= 400) {
      analyticsService.trackApiError(url, method, status, `HTTP ${status}`);
    }
  }, [userId]);

  // Business event logging
  const logBusinessEvent = useCallback((
    event: string,
    entityType: string,
    entityId: string,
    context?: Record<string, any>
  ) => {
    loggingService.logBusinessEvent(event, entityType, entityId, context, userId);
  }, [userId]);

  // Form logging
  const logFormSubmission = useCallback((formName: string, screen: string, success: boolean, context?: Record<string, any>) => {
    logInfo(`Form ${success ? 'submitted' : 'failed'}: ${formName}`, {
      screen,
      success,
      ...context,
    });
    
    analyticsService.trackFormSubmitted(formName, screen, success);
  }, [logInfo]);

  // Error logging with analytics
  const logErrorWithAnalytics = useCallback((
    errorType: string,
    errorMessage: string,
    screen?: string,
    context?: Record<string, any>
  ) => {
    logError(`${errorType}: ${errorMessage}`, { screen, ...context });
    analyticsService.trackError(errorType, errorMessage, screen, context);
  }, [logError]);

  // File upload logging
  const logFileUpload = useCallback((
    fileType: string,
    fileSize: number,
    uploadTime: number,
    success: boolean,
    context?: Record<string, any>
  ) => {
    logInfo(`File upload ${success ? 'completed' : 'failed'}`, {
      file_type: fileType,
      file_size: fileSize,
      upload_time: uploadTime,
      success,
      ...context,
    });

    if (success) {
      analyticsService.trackFileUploaded(fileType, fileSize, uploadTime);
    } else {
      analyticsService.trackError('file_upload_error', 'File upload failed', undefined, {
        file_type: fileType,
        file_size: fileSize,
        ...context,
      });
    }
  }, [logInfo]);

  // Search logging
  const logSearch = useCallback((
    query: string,
    screen: string,
    resultCount: number,
    context?: Record<string, any>
  ) => {
    logInfo('Search performed', {
      query,
      screen,
      result_count: resultCount,
      ...context,
    });

    analyticsService.trackSearchPerformed(query, screen, resultCount);
  }, [logInfo]);

  // Feature usage logging
  const logFeatureUsage = useCallback((featureName: string, context?: Record<string, any>) => {
    logInfo(`Feature used: ${featureName}`, context);
    analyticsService.trackFeatureUsed(featureName, context);
  }, [logInfo]);

  // Workflow logging
  const logWorkflowStart = useCallback((workflowName: string, context?: Record<string, any>) => {
    logInfo(`Workflow started: ${workflowName}`, context);
    analyticsService.trackWorkflowStarted(workflowName, context);
  }, [logInfo]);

  const logWorkflowComplete = useCallback((
    workflowName: string,
    duration: number,
    context?: Record<string, any>
  ) => {
    logInfo(`Workflow completed: ${workflowName}`, { duration_ms: duration, ...context });
    analyticsService.trackWorkflowCompleted(workflowName, duration, context);
  }, [logInfo]);

  const logWorkflowAbandoned = useCallback((
    workflowName: string,
    step: string,
    context?: Record<string, any>
  ) => {
    logWarn(`Workflow abandoned: ${workflowName} at step ${step}`, context);
    analyticsService.trackWorkflowAbandoned(workflowName, step, context);
  }, [logWarn]);

  return {
    // Basic logging
    logDebug,
    logInfo,
    logWarn,
    logError,
    
    // Specialized logging
    logPerformance,
    logUserAction,
    logNavigation,
    logApiRequest,
    logBusinessEvent,
    logFormSubmission,
    logErrorWithAnalytics,
    logFileUpload,
    logSearch,
    logFeatureUsage,
    
    // Workflow logging
    logWorkflowStart,
    logWorkflowComplete,
    logWorkflowAbandoned,
  };
};