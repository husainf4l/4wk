import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { navigationRef } from '../services/NavigationService';
import { RootStackParamList } from './types';
import { useAppState } from '../context/AppStateContext';

// Import screens (these will need to be implemented)
import LoginScreen from '../screens/auth/LoginScreen';
import MainTabNavigator from './MainTabNavigator';
import AddCustomerScreen from '../screens/customers/AddCustomerScreen';
import CustomerDetailsScreen from '../screens/customers/CustomerDetailsScreen';
import AddCarScreen from '../screens/cars/AddCarScreen';
import CarDetailsScreen from '../screens/cars/CarDetailsScreen';
import CreateSessionScreen from '../screens/sessions/CreateSessionScreen';
import SessionDetailsScreen from '../screens/sessions/SessionDetailsScreen';
import InspectionScreen from '../screens/inspection/InspectionScreen';
import TestDriveScreen from '../screens/testDrive/TestDriveScreen';
import ReportScreen from '../screens/report/ReportScreen';
import JobOrderScreen from '../screens/jobOrder/JobOrderScreen';
import SettingsScreen from '../screens/settings/SettingsScreen';
import ProfileScreen from '../screens/profile/ProfileScreen';

const Stack = createStackNavigator<RootStackParamList>();

const RootNavigator: React.FC = () => {
  const { state } = useAppState();

  const defaultScreenOptions = {
    headerShown: true,
    headerStyle: {
      backgroundColor: '#FFFFFF',
      elevation: 1,
      shadowOpacity: 0.1,
    },
    headerTitleStyle: {
      fontSize: 18,
      fontWeight: '600' as const,
      color: '#111827',
    },
    headerTintColor: '#DC2626',
    gestureEnabled: true,
  };

  return (
    <NavigationContainer ref={navigationRef}>
      <Stack.Navigator
        initialRouteName={state.isAuthenticated ? 'MainTabs' : 'Login'}
        screenOptions={defaultScreenOptions}
      >
        {!state.isAuthenticated ? (
          // Auth Stack
          <Stack.Group>
            <Stack.Screen
              name="Login"
              component={LoginScreen}
              options={{
                headerShown: false,
              }}
            />
          </Stack.Group>
        ) : (
          // App Stack
          <Stack.Group>
            {/* Main Tab Navigator */}
            <Stack.Screen
              name="MainTabs"
              component={MainTabNavigator}
              options={{
                headerShown: false,
              }}
            />

            {/* Customer Flow */}
            <Stack.Screen
              name="AddCustomer"
              component={AddCustomerScreen}
              options={{
                title: 'Add Customer',
                presentation: 'modal',
              }}
            />
            <Stack.Screen
              name="CustomerDetails"
              component={CustomerDetailsScreen}
              options={{
                title: 'Customer Details',
              }}
            />

            {/* Car Flow */}
            <Stack.Screen
              name="AddCar"
              component={AddCarScreen}
              options={{
                title: 'Add Car',
                presentation: 'modal',
              }}
            />
            <Stack.Screen
              name="CarDetails"
              component={CarDetailsScreen}
              options={{
                title: 'Car Details',
              }}
            />

            {/* Session Flow */}
            <Stack.Screen
              name="CreateSession"
              component={CreateSessionScreen}
              options={{
                title: 'Create Session',
                presentation: 'modal',
              }}
            />
            <Stack.Screen
              name="SessionDetails"
              component={SessionDetailsScreen}
              options={{
                title: 'Session Details',
              }}
            />

            {/* Inspection Flow */}
            <Stack.Screen
              name="Inspection"
              component={InspectionScreen}
              options={{
                title: 'Vehicle Inspection',
              }}
            />

            {/* Test Drive Flow */}
            <Stack.Screen
              name="TestDrive"
              component={TestDriveScreen}
              options={{
                title: 'Test Drive',
              }}
            />

            {/* Report Flow */}
            <Stack.Screen
              name="Report"
              component={ReportScreen}
              options={{
                title: 'Inspection Report',
              }}
            />

            {/* Job Order Flow */}
            <Stack.Screen
              name="JobOrder"
              component={JobOrderScreen}
              options={{
                title: 'Job Order',
              }}
            />

            {/* Settings */}
            <Stack.Screen
              name="Settings"
              component={SettingsScreen}
              options={{
                title: 'Settings',
              }}
            />
            <Stack.Screen
              name="Profile"
              component={ProfileScreen}
              options={{
                title: 'Profile',
              }}
            />
          </Stack.Group>
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
};

export default RootNavigator;