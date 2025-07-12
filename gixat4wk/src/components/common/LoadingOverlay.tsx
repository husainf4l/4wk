import React from 'react';
import { View, ActivityIndicator, Text, StyleSheet, Modal } from 'react-native';
import { LoadingState } from '../../types/api';

interface LoadingOverlayProps {
  visible: boolean;
  message?: string;
  transparent?: boolean;
}

export const LoadingOverlay: React.FC<LoadingOverlayProps> = ({
  visible,
  message = 'Loading...',
  transparent = true,
}) => {
  if (!visible) return null;

  return (
    <Modal transparent={transparent} animationType="fade" visible={visible}>
      <View style={styles.overlay}>
        <View style={styles.container}>
          <ActivityIndicator size="large" color="#DC2626" />
          <Text style={styles.message}>{message}</Text>
        </View>
      </View>
    </Modal>
  );
};

interface LoadingStateComponentProps {
  loading: LoadingState;
  error?: string | null;
  children: React.ReactNode;
  loadingMessage?: string;
  errorComponent?: React.ReactNode;
  emptyComponent?: React.ReactNode;
  showData?: boolean;
}

export const LoadingStateComponent: React.FC<LoadingStateComponentProps> = ({
  loading,
  error,
  children,
  loadingMessage = 'Loading...',
  errorComponent,
  emptyComponent,
  showData = false,
}) => {
  if (loading === 'loading') {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" color="#DC2626" />
        <Text style={styles.loadingText}>{loadingMessage}</Text>
      </View>
    );
  }

  if (loading === 'error' && error) {
    if (errorComponent) {
      return <>{errorComponent}</>;
    }
    
    return (
      <View style={styles.centerContainer}>
        <Text style={styles.errorText}>Error: {error}</Text>
      </View>
    );
  }

  if (loading === 'success' && !showData && emptyComponent) {
    return <>{emptyComponent}</>;
  }

  return <>{children}</>;
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  container: {
    backgroundColor: 'white',
    padding: 20,
    borderRadius: 10,
    alignItems: 'center',
    minWidth: 150,
  },
  message: {
    marginTop: 10,
    fontSize: 16,
    color: '#374151',
    textAlign: 'center',
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  loadingText: {
    marginTop: 10,
    fontSize: 16,
    color: '#6B7280',
    textAlign: 'center',
  },
  errorText: {
    fontSize: 16,
    color: '#DC2626',
    textAlign: 'center',
  },
});