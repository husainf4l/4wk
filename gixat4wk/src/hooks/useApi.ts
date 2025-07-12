import { useCallback } from 'react';
import { useAsync } from './useAsync';
import { ApiResponse } from '../types/api';

export interface UseApiOptions {
  immediate?: boolean;
  onSuccess?: (data: any) => void;
  onError?: (error: string) => void;
  showSuccessMessage?: boolean;
  showErrorMessage?: boolean;
}

export function useApi<T = any>(
  apiFunction: (...args: any[]) => Promise<ApiResponse<T>>,
  options: UseApiOptions = {}
) {
  const { showSuccessMessage = false, showErrorMessage = true, ...asyncOptions } = options;

  const wrappedFunction = useCallback(
    async (...args: any[]) => {
      const response = await apiFunction(...args);
      
      if (!response.success) {
        throw new Error(response.error || 'API request failed');
      }

      return response.data;
    },
    [apiFunction]
  );

  const {
    data,
    loading,
    error,
    execute,
    reset,
    setData,
    setError,
    isLoading,
    isSuccess,
    isError,
    isIdle,
    lastFetched,
  } = useAsync<T>(wrappedFunction, {
    ...asyncOptions,
    onSuccess: (data) => {
      if (showSuccessMessage) {
        // You can integrate with a toast/notification system here
        console.log('API Success:', data);
      }
      if (asyncOptions.onSuccess) {
        asyncOptions.onSuccess(data);
      }
    },
    onError: (error) => {
      if (showErrorMessage) {
        // You can integrate with a toast/notification system here
        console.error('API Error:', error);
      }
      if (asyncOptions.onError) {
        asyncOptions.onError(error);
      }
    },
  });

  const executeWithValidation = useCallback(
    async (...args: any[]) => {
      try {
        return await execute(...args);
      } catch (error) {
        // Error is already handled by the async hook
        return null;
      }
    },
    [execute]
  );

  return {
    data,
    loading,
    error,
    execute: executeWithValidation,
    reset,
    setData,
    setError,
    isLoading,
    isSuccess,
    isError,
    isIdle,
    lastFetched,
  };
}