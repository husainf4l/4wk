import React, { createContext, useContext, useReducer, ReactNode } from 'react';
import { Customer } from '../types/Customer';
import { Car } from '../types/Car';
import { Session } from '../types/Session';
import { User } from '../types/User';

interface AppState {
  user: User | null;
  currentCustomer: Customer | null;
  currentCar: Car | null;
  currentSession: Session | null;
  isAuthenticated: boolean;
  networkStatus: 'online' | 'offline';
  appVersion: string;
}

type AppAction =
  | { type: 'SET_USER'; payload: User | null }
  | { type: 'SET_CURRENT_CUSTOMER'; payload: Customer | null }
  | { type: 'SET_CURRENT_CAR'; payload: Car | null }
  | { type: 'SET_CURRENT_SESSION'; payload: Session | null }
  | { type: 'SET_AUTHENTICATED'; payload: boolean }
  | { type: 'SET_NETWORK_STATUS'; payload: 'online' | 'offline' }
  | { type: 'RESET_WORKFLOW' }
  | { type: 'RESET_APP' };

const initialState: AppState = {
  user: null,
  currentCustomer: null,
  currentCar: null,
  currentSession: null,
  isAuthenticated: false,
  networkStatus: 'online',
  appVersion: '1.0.0',
};

function appStateReducer(state: AppState, action: AppAction): AppState {
  switch (action.type) {
    case 'SET_USER':
      return {
        ...state,
        user: action.payload,
      };
    
    case 'SET_CURRENT_CUSTOMER':
      return {
        ...state,
        currentCustomer: action.payload,
        // Reset car and session when customer changes
        currentCar: action.payload ? state.currentCar : null,
        currentSession: action.payload ? state.currentSession : null,
      };
    
    case 'SET_CURRENT_CAR':
      return {
        ...state,
        currentCar: action.payload,
        // Reset session when car changes
        currentSession: action.payload ? state.currentSession : null,
      };
    
    case 'SET_CURRENT_SESSION':
      return {
        ...state,
        currentSession: action.payload,
      };
    
    case 'SET_AUTHENTICATED':
      return {
        ...state,
        isAuthenticated: action.payload,
        // Clear user data when not authenticated
        user: action.payload ? state.user : null,
      };
    
    case 'SET_NETWORK_STATUS':
      return {
        ...state,
        networkStatus: action.payload,
      };
    
    case 'RESET_WORKFLOW':
      return {
        ...state,
        currentCustomer: null,
        currentCar: null,
        currentSession: null,
      };
    
    case 'RESET_APP':
      return {
        ...initialState,
        appVersion: state.appVersion,
      };
    
    default:
      return state;
  }
}

interface AppStateContextValue {
  state: AppState;
  setUser: (user: User | null) => void;
  setCurrentCustomer: (customer: Customer | null) => void;
  setCurrentCar: (car: Car | null) => void;
  setCurrentSession: (session: Session | null) => void;
  setAuthenticated: (isAuthenticated: boolean) => void;
  setNetworkStatus: (status: 'online' | 'offline') => void;
  resetWorkflow: () => void;
  resetApp: () => void;
}

const AppStateContext = createContext<AppStateContextValue | undefined>(undefined);

interface AppStateProviderProps {
  children: ReactNode;
}

export const AppStateProvider: React.FC<AppStateProviderProps> = ({ children }) => {
  const [state, dispatch] = useReducer(appStateReducer, initialState);

  const setUser = (user: User | null) => {
    dispatch({ type: 'SET_USER', payload: user });
  };

  const setCurrentCustomer = (customer: Customer | null) => {
    dispatch({ type: 'SET_CURRENT_CUSTOMER', payload: customer });
  };

  const setCurrentCar = (car: Car | null) => {
    dispatch({ type: 'SET_CURRENT_CAR', payload: car });
  };

  const setCurrentSession = (session: Session | null) => {
    dispatch({ type: 'SET_CURRENT_SESSION', payload: session });
  };

  const setAuthenticated = (isAuthenticated: boolean) => {
    dispatch({ type: 'SET_AUTHENTICATED', payload: isAuthenticated });
  };

  const setNetworkStatus = (status: 'online' | 'offline') => {
    dispatch({ type: 'SET_NETWORK_STATUS', payload: status });
  };

  const resetWorkflow = () => {
    dispatch({ type: 'RESET_WORKFLOW' });
  };

  const resetApp = () => {
    dispatch({ type: 'RESET_APP' });
  };

  const value: AppStateContextValue = {
    state,
    setUser,
    setCurrentCustomer,
    setCurrentCar,
    setCurrentSession,
    setAuthenticated,
    setNetworkStatus,
    resetWorkflow,
    resetApp,
  };

  return (
    <AppStateContext.Provider value={value}>
      {children}
    </AppStateContext.Provider>
  );
};

export const useAppState = (): AppStateContextValue => {
  const context = useContext(AppStateContext);
  if (context === undefined) {
    throw new Error('useAppState must be used within an AppStateProvider');
  }
  return context;
};