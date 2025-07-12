import { NavigationContainerRef, CommonActions, StackActions } from '@react-navigation/native';
import { createRef } from 'react';

export const navigationRef = createRef<NavigationContainerRef<any>>();

export interface NavigationParams {
  [key: string]: any;
}

export class NavigationService {
  static navigate(name: string, params?: NavigationParams) {
    if (navigationRef.current) {
      navigationRef.current.navigate(name as never, params as never);
    }
  }

  static push(name: string, params?: NavigationParams) {
    if (navigationRef.current) {
      navigationRef.current.dispatch(StackActions.push(name, params));
    }
  }

  static replace(name: string, params?: NavigationParams) {
    if (navigationRef.current) {
      navigationRef.current.dispatch(StackActions.replace(name, params));
    }
  }

  static goBack() {
    if (navigationRef.current && navigationRef.current.canGoBack()) {
      navigationRef.current.goBack();
    }
  }

  static popToTop() {
    if (navigationRef.current) {
      navigationRef.current.dispatch(StackActions.popToTop());
    }
  }

  static reset(routeName: string, params?: NavigationParams) {
    if (navigationRef.current) {
      navigationRef.current.dispatch(
        CommonActions.reset({
          index: 0,
          routes: [{ name: routeName, params }],
        })
      );
    }
  }

  static getCurrentRoute() {
    if (navigationRef.current) {
      return navigationRef.current.getCurrentRoute();
    }
    return null;
  }

  static getState() {
    if (navigationRef.current) {
      return navigationRef.current.getState();
    }
    return null;
  }

  static canGoBack(): boolean {
    if (navigationRef.current) {
      return navigationRef.current.canGoBack();
    }
    return false;
  }

  // Workflow navigation helpers
  static navigateToCustomerWorkflow(customerId?: string) {
    this.navigate('AddCustomer', customerId ? { customerId } : undefined);
  }

  static navigateToCarWorkflow(customerId: string, carId?: string) {
    this.navigate('AddCar', { customerId, carId });
  }

  static navigateToSessionWorkflow(customerId: string, carId: string, sessionId?: string) {
    this.navigate('CreateSession', { customerId, carId, sessionId });
  }

  static navigateToSessionDetails(sessionId: string) {
    this.navigate('SessionDetails', { sessionId });
  }

  static navigateToInspection(sessionId: string) {
    this.navigate('Inspection', { sessionId });
  }

  static navigateToTestDrive(sessionId: string) {
    this.navigate('TestDrive', { sessionId });
  }

  static navigateToReport(sessionId: string) {
    this.navigate('Report', { sessionId });
  }

  static navigateToJobOrder(sessionId: string) {
    this.navigate('JobOrder', { sessionId });
  }

  // Auth navigation
  static navigateToLogin() {
    this.reset('Login');
  }

  static navigateToHome() {
    this.reset('Home');
  }

  static navigateToDashboard() {
    this.reset('Dashboard');
  }

  // Tab navigation helpers
  static switchToTab(tabName: string) {
    this.navigate(tabName);
  }

  // Modal navigation
  static openModal(modalName: string, params?: NavigationParams) {
    this.navigate(modalName, params);
  }

  static closeModal() {
    this.goBack();
  }

  // Deep linking helpers
  static handleDeepLink(url: string) {
    try {
      const urlParts = url.split('://')[1]?.split('/') || [];
      const action = urlParts[0];
      const id = urlParts[1];

      switch (action) {
        case 'customer':
          if (id) {
            this.navigate('CustomerDetails', { customerId: id });
          }
          break;
        case 'car':
          if (id) {
            this.navigate('CarDetails', { carId: id });
          }
          break;
        case 'session':
          if (id) {
            this.navigate('SessionDetails', { sessionId: id });
          }
          break;
        case 'report':
          if (id) {
            this.navigate('Report', { sessionId: id });
          }
          break;
        default:
          this.navigateToHome();
      }
    } catch (error) {
      console.error('Error handling deep link:', error);
      this.navigateToHome();
    }
  }

  // Navigation state persistence
  static getNavigationState() {
    return this.getState();
  }

  static restoreNavigationState(state: any) {
    if (navigationRef.current && state) {
      navigationRef.current.resetRoot(state);
    }
  }
}

export const navigationService = NavigationService;