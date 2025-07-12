import React from 'react';
import { Text } from 'react-native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { MainTabParamList } from './types';

// Import screens (these will need to be implemented)
import DashboardScreen from '../screens/dashboard/DashboardScreen';
import CustomersScreen from '../screens/customers/CustomersScreen';
import SessionsScreen from '../screens/sessions/SessionsScreen';
import ReportsScreen from '../screens/reports/ReportsScreen';
import ProfileScreen from '../screens/profile/ProfileScreen';

// Icons (you'll need to add react-native-vector-icons or similar)
// For now, using Text placeholders
const TabIcon = ({ name, focused }: { name: string; focused: boolean }) => (
  <Text style={{ color: focused ? '#DC2626' : '#6B7280', fontSize: 12 }}>
    {name}
  </Text>
);

const Tab = createBottomTabNavigator<MainTabParamList>();

const MainTabNavigator: React.FC = () => {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused }) => (
          <TabIcon 
            name={route.name} 
            focused={focused} 
          />
        ),
        tabBarActiveTintColor: '#DC2626',
        tabBarInactiveTintColor: '#6B7280',
        tabBarStyle: {
          backgroundColor: '#FFFFFF',
          borderTopWidth: 1,
          borderTopColor: '#E5E7EB',
          paddingBottom: 5,
          paddingTop: 5,
          height: 60,
        },
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: '500',
          marginTop: 2,
        },
        headerShown: true,
        headerStyle: {
          backgroundColor: '#FFFFFF',
          elevation: 1,
          shadowOpacity: 0.1,
        },
        headerTitleStyle: {
          fontSize: 20,
          fontWeight: '600',
          color: '#111827',
        },
        headerTintColor: '#DC2626',
      })}
    >
      <Tab.Screen
        name="Dashboard"
        component={DashboardScreen}
        options={{
          title: 'Dashboard',
          tabBarLabel: 'Dashboard',
        }}
      />
      <Tab.Screen
        name="Customers"
        component={CustomersScreen}
        options={{
          title: 'Customers',
          tabBarLabel: 'Customers',
        }}
      />
      <Tab.Screen
        name="Sessions"
        component={SessionsScreen}
        options={{
          title: 'Active Sessions',
          tabBarLabel: 'Sessions',
        }}
      />
      <Tab.Screen
        name="Reports"
        component={ReportsScreen}
        options={{
          title: 'Reports',
          tabBarLabel: 'Reports',
        }}
      />
      <Tab.Screen
        name="Profile"
        component={ProfileScreen}
        options={{
          title: 'Profile',
          tabBarLabel: 'Profile',
        }}
      />
    </Tab.Navigator>
  );
};

export default MainTabNavigator;