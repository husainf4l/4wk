import { useState, useCallback, useRef, useEffect } from 'react';
import { AsyncState, LoadingState } from '../types/api';

export interface UseAsyncOptions {
  immediate?: boolean;
  onSuccess?: (data: any) => void;
  onError?: (error: string) => void;
}

export function useAsync<T = any>(
  asyncFunction: (...args: any[]) => Promise<T>,
  options: UseAsyncOptions = {}
) {
  const { immediate = false, onSuccess, onError } = options;
  
  const [state, setState] = useState<AsyncState<T>>({
    data: null,
    loading: 'idle',
    error: null,
    lastFetched: undefined,
  });

  const mountedRef = useRef(true);

  useEffect(() => {
    return () => {
      mountedRef.current = false;
    };
  }, []);

  const execute = useCallback(
    async (...args: any[]) => {
      if (!mountedRef.current) return;

      setState(prev => ({
        ...prev,
        loading: 'loading',
        error: null,
      }));

      try {
        const data = await asyncFunction(...args);
        
        if (!mountedRef.current) return;

        setState({
          data,
          loading: 'success',
          error: null,
          lastFetched: new Date(),
        });

        if (onSuccess) {
          onSuccess(data);
        }

        return data;
      } catch (error) {
        if (!mountedRef.current) return;

        const errorMessage = error instanceof Error ? error.message : 'An error occurred';
        
        setState(prev => ({
          ...prev,
          loading: 'error',
          error: errorMessage,
        }));

        if (onError) {
          onError(errorMessage);
        }

        throw error;
      }
    },
    [asyncFunction, onSuccess, onError]
  );

  const reset = useCallback(() => {
    setState({
      data: null,
      loading: 'idle',
      error: null,
      lastFetched: undefined,
    });
  }, []);

  const setData = useCallback((data: T) => {
    setState(prev => ({
      ...prev,
      data,
      loading: 'success',
      error: null,
      lastFetched: new Date(),
    }));
  }, []);

  const setError = useCallback((error: string) => {
    setState(prev => ({
      ...prev,
      loading: 'error',
      error,
    }));
  }, []);

  useEffect(() => {
    if (immediate) {
      execute();
    }
  }, [immediate, execute]);

  return {
    ...state,
    execute,
    reset,
    setData,
    setError,
    isLoading: state.loading === 'loading',
    isSuccess: state.loading === 'success',
    isError: state.loading === 'error',
    isIdle: state.loading === 'idle',
  };
}