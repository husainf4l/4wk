/**
 * 4WK Garage Management System
 * Powered by Gixat
 *
 * @format
 */

import React from 'react';
import { StatusBar, StyleSheet, View } from 'react-native';
import { AddCustomerScreen } from './src/screens/customers/AddCustomerScreen';
import { theme } from './src/styles/theme';

function App() {
  return (
    <View style={styles.container}>
      <StatusBar 
        barStyle="dark-content" 
        backgroundColor={theme.colors.background}
        translucent={false}
      />
      <AddCustomerScreen />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
});

export default App;
