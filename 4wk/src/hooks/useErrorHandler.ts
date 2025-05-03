import { useState, useCallback } from 'react';

interface ErrorState {
  isError: boolean;
  message: string;
}

export default function useErrorHandler() {
  const [error, setError] = useState<ErrorState>({
    isError: false,
    message: '',
  });

  const handleError = useCallback((error: unknown) => {
    console.error('Error caught by handler:', error);
    let message = 'An unexpected error occurred';

    if (error instanceof Error) {
      message = error.message;
    } else if (typeof error === 'string') {
      message = error;
    } else if (error && typeof error === 'object' && 'message' in error) {
      message = String((error as { message: unknown }).message);
    }
    
    setError({ isError: true, message });
    return message;
  }, []);

  const clearError = useCallback(() => {
    setError({ isError: false, message: '' });
  }, []);

  return { error, handleError, clearError };
}