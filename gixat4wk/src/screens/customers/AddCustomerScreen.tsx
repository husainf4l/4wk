import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  Alert,
  Switch,
} from 'react-native';
import { theme } from '../../styles/theme';
import { Button } from '../../components/Button';
import { Input } from '../../components/Input';
import { CreateCustomerData } from '../../types/Customer';

export const AddCustomerScreen: React.FC = () => {
  const [formData, setFormData] = useState<CreateCustomerData>({
    name: '',
    phone: '',
    email: '',
    isCompany: false,
    companyName: '',
    address: '',
    notes: '',
  });
  const [errors, setErrors] = useState<{[key: string]: string}>({});
  const [loading, setLoading] = useState(false);

  const validateForm = () => {
    const newErrors: {[key: string]: string} = {};
    
    if (!formData.name.trim()) {
      newErrors.name = 'Name is required';
    }
    
    if (!formData.phone.trim()) {
      newErrors.phone = 'Phone number is required';
    } else if (!/^\+?[\d\s-()]+$/.test(formData.phone)) {
      newErrors.phone = 'Please enter a valid phone number';
    }
    
    if (formData.isCompany && !formData.companyName?.trim()) {
      newErrors.companyName = 'Company name is required';
    }
    
    if (formData.email && !/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = 'Please enter a valid email';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSave = async () => {
    if (!validateForm()) return;
    
    setLoading(true);
    try {
      // TODO: Implement customer creation API call
      console.log('Creating customer:', formData);
      
      // For now, just show success and navigate to car registration
      Alert.alert(
        'Customer Created',
        'Customer has been created successfully. Now add their car.',
        [
          {
            text: 'Add Car',
            onPress: () => {
              // TODO: Navigate to add car screen with customer ID
              console.log('Navigate to add car screen');
            }
          }
        ]
      );
    } catch (error) {
      Alert.alert('Error', 'Failed to create customer');
    } finally {
      setLoading(false);
    }
  };

  const updateField = (field: keyof CreateCustomerData, value: string | boolean) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.scrollView}>
        <View style={styles.header}>
          <Text style={styles.title}>Add Customer</Text>
          <Text style={styles.subtitle}>Create new customer record</Text>
        </View>

        <View style={styles.form}>
          <Input
            label="Customer Name *"
            value={formData.name}
            onChangeText={(value) => updateField('name', value)}
            placeholder="Enter customer name"
            error={errors.name}
            leftIcon={<Text style={styles.icon}>👤</Text>}
          />

          <Input
            label="Phone Number *"
            value={formData.phone}
            onChangeText={(value) => updateField('phone', value)}
            placeholder="+971 50 123 4567"
            keyboardType="phone-pad"
            error={errors.phone}
            leftIcon={<Text style={styles.icon}>📞</Text>}
          />

          <View style={styles.switchContainer}>
            <Text style={styles.switchLabel}>Is this a company?</Text>
            <Switch
              value={formData.isCompany}
              onValueChange={(value) => updateField('isCompany', value)}
              trackColor={{ false: theme.colors.border, true: theme.colors.primary }}
              thumbColor={formData.isCompany ? '#FFFFFF' : theme.colors.textLight}
            />
          </View>

          {formData.isCompany && (
            <Input
              label="Company Name *"
              value={formData.companyName || ''}
              onChangeText={(value) => updateField('companyName', value)}
              placeholder="Enter company name"
              error={errors.companyName}
              leftIcon={<Text style={styles.icon}>🏢</Text>}
            />
          )}

          <Input
            label="Email"
            value={formData.email || ''}
            onChangeText={(value) => updateField('email', value)}
            placeholder="customer@example.com"
            keyboardType="email-address"
            autoCapitalize="none"
            error={errors.email}
            leftIcon={<Text style={styles.icon}>📧</Text>}
          />

          <Input
            label="Address"
            value={formData.address || ''}
            onChangeText={(value) => updateField('address', value)}
            placeholder="Enter address"
            multiline
            leftIcon={<Text style={styles.icon}>📍</Text>}
          />

          <Input
            label="Notes"
            value={formData.notes || ''}
            onChangeText={(value) => updateField('notes', value)}
            placeholder="Additional notes"
            multiline
            leftIcon={<Text style={styles.icon}>📝</Text>}
          />

          <Button
            title="Create Customer & Add Car"
            onPress={handleSave}
            loading={loading}
            style={styles.saveButton}
          />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  scrollView: {
    flex: 1,
  },
  header: {
    padding: theme.spacing.lg,
    backgroundColor: theme.colors.surface,
  },
  title: {
    fontSize: theme.fonts.sizes.xxxl,
    fontWeight: theme.fonts.weights.bold,
    color: theme.colors.text,
    marginBottom: theme.spacing.xs,
  },
  subtitle: {
    fontSize: theme.fonts.sizes.md,
    color: theme.colors.textSecondary,
  },
  form: {
    padding: theme.spacing.lg,
  },
  icon: {
    fontSize: 18,
  },
  switchContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.md,
    paddingVertical: theme.spacing.md,
    paddingHorizontal: theme.spacing.sm,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.medium,
  },
  switchLabel: {
    fontSize: theme.fonts.sizes.md,
    fontWeight: theme.fonts.weights.medium,
    color: theme.colors.text,
  },
  saveButton: {
    marginTop: theme.spacing.lg,
  },
});