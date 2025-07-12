import { useEffect, useState, useCallback } from 'react';
import { persistenceService } from '../services/PersistenceService';
import { useLogging } from './useLogging';

export interface UsePersistenceOptions {
  key: string;
  defaultValue?: any;
  encrypt?: boolean;
  compress?: boolean;
  autoSave?: boolean;
  debounceMs?: number;
}

export function usePersistence<T>(options: UsePersistenceOptions) {
  const { key, defaultValue, encrypt, compress, autoSave = true, debounceMs = 1000 } = options;
  const [data, setData] = useState<T | null>(defaultValue || null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { logError, logInfo } = useLogging();

  // Load data on mount
  useEffect(() => {
    const loadData = async () => {
      try {
        setIsLoading(true);
        setError(null);
        
        const stored = await persistenceService.retrieve<T>(key, {
          decrypt: encrypt,
          decompress: compress,
        });
        
        if (stored !== null) {
          setData(stored);
          logInfo('Persistence data loaded', { key });
        } else if (defaultValue !== undefined) {
          setData(defaultValue);
        }
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Unknown error';
        setError(errorMessage);
        logError('Failed to load persistent data', { key, error: errorMessage });
        
        // Fallback to default value on error
        if (defaultValue !== undefined) {
          setData(defaultValue);
        }
      } finally {
        setIsLoading(false);
      }
    };

    loadData();
  }, [key, encrypt, compress, defaultValue, logError, logInfo]);

  // Save data function
  const saveData = useCallback(async (newData: T) => {
    try {
      setIsSaving(true);
      setError(null);
      
      await persistenceService.store(key, newData, {
        encrypt,
        compress,
      });
      
      logInfo('Persistence data saved', { key });
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error';
      setError(errorMessage);
      logError('Failed to save persistent data', { key, error: errorMessage });
      throw err;
    } finally {
      setIsSaving(false);
    }
  }, [key, encrypt, compress, logError, logInfo]);

  // Debounced save for auto-save
  const [saveTimeout, setSaveTimeout] = useState<NodeJS.Timeout | null>(null);

  const debouncedSave = useCallback((newData: T) => {
    if (saveTimeout) {
      clearTimeout(saveTimeout);
    }

    const timeout = setTimeout(() => {
      saveData(newData);
    }, debounceMs);

    setSaveTimeout(timeout);
  }, [saveData, debounceMs, saveTimeout]);

  // Update data function
  const updateData = useCallback((newData: T | ((prev: T | null) => T)) => {
    setData(prevData => {
      const updatedData = typeof newData === 'function' 
        ? (newData as (prev: T | null) => T)(prevData)
        : newData;
      
      if (autoSave) {
        debouncedSave(updatedData);
      }
      
      return updatedData;
    });
  }, [autoSave, debouncedSave]);

  // Manual save function
  const save = useCallback(async () => {
    if (data !== null) {
      await saveData(data);
    }
  }, [data, saveData]);

  // Clear data function
  const clear = useCallback(async () => {
    try {
      await persistenceService.remove(key);
      setData(defaultValue || null);
      setError(null);
      logInfo('Persistence data cleared', { key });
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error';
      setError(errorMessage);
      logError('Failed to clear persistent data', { key, error: errorMessage });
      throw err;
    }
  }, [key, defaultValue, logError, logInfo]);

  // Cleanup timeout on unmount
  useEffect(() => {
    return () => {
      if (saveTimeout) {
        clearTimeout(saveTimeout);
      }
    };
  }, [saveTimeout]);

  return {
    data,
    setData: updateData,
    save,
    clear,
    isLoading,
    isSaving,
    error,
    isReady: !isLoading && error === null,
  };
}

// Specialized hooks for common use cases
export function usePersistedForm<T>(formId: string, initialData?: T) {
  return usePersistence<T>({
    key: `form_data:${formId}`,
    defaultValue: initialData,
    autoSave: true,
    debounceMs: 2000, // Longer debounce for forms
  });
}

export function usePersistedDraft<T>(type: string, id: string, initialData?: T) {
  return usePersistence<T>({
    key: `draft:${type}:${id}`,
    defaultValue: initialData,
    autoSave: true,
    debounceMs: 1500,
  });
}

export function usePersistedSettings<T>(defaultSettings: T) {
  return usePersistence<T>({
    key: 'app_settings',
    defaultValue: defaultSettings,
    autoSave: true,
    debounceMs: 500,
  });
}

export function usePersistedSearchHistory(type: string) {
  const [history, setHistory] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const loadHistory = async () => {
      try {
        const stored = await persistenceService.hydrateSearchHistory(type);
        setHistory(stored);
      } catch (error) {
        console.error('Failed to load search history:', error);
      } finally {
        setIsLoading(false);
      }
    };

    loadHistory();
  }, [type]);

  const addToHistory = useCallback(async (query: string) => {
    try {
      await persistenceService.persistSearchHistory(query, type);
      const updated = await persistenceService.hydrateSearchHistory(type);
      setHistory(updated);
    } catch (error) {
      console.error('Failed to add to search history:', error);
    }
  }, [type]);

  const clearHistory = useCallback(async () => {
    try {
      await persistenceService.remove(`search_history:${type}`);
      setHistory([]);
    } catch (error) {
      console.error('Failed to clear search history:', error);
    }
  }, [type]);

  return {
    history,
    addToHistory,
    clearHistory,
    isLoading,
  };
}

export function usePersistedRecentlyViewed<T>(type: string) {
  const [items, setItems] = useState<T[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const loadItems = async () => {
      try {
        const stored = await persistenceService.hydrateRecentlyViewed(type);
        setItems(stored);
      } catch (error) {
        console.error('Failed to load recently viewed items:', error);
      } finally {
        setIsLoading(false);
      }
    };

    loadItems();
  }, [type]);

  const addItem = useCallback(async (item: T) => {
    try {
      await persistenceService.persistRecentlyViewed(type, item);
      const updated = await persistenceService.hydrateRecentlyViewed(type);
      setItems(updated);
    } catch (error) {
      console.error('Failed to add recently viewed item:', error);
    }
  }, [type]);

  const clearItems = useCallback(async () => {
    try {
      await persistenceService.remove(`recent:${type}`);
      setItems([]);
    } catch (error) {
      console.error('Failed to clear recently viewed items:', error);
    }
  }, [type]);

  return {
    items,
    addItem,
    clearItems,
    isLoading,
  };
}