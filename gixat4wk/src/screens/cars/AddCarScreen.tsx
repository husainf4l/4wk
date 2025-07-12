import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  Alert,
} from 'react-native';
import { theme } from '../../styles/theme';
import { Button } from '../../components/Button';
import { Input } from '../../components/Input';
import { CreateCarData } from '../../types/Car';

interface AddCarScreenProps {
  customerId?: string;
  customerName?: string;
}

export const AddCarScreen: React.FC<AddCarScreenProps> = ({ 
  customerId, 
  customerName 
}) => {
  const [formData, setFormData] = useState<Partial<CreateCarData>>({
    customerId: customerId || '',
    make: '',
    model: '',
    year: new Date().getFullYear(),
    color: '',
    plateNumber: '',
    emirate: '',
    vin: '',
    fuelType: 'petrol',
    transmission: 'automatic',
    currentMileage: 0,
    notes: '',
  });
  const [errors, setErrors] = useState<{[key: string]: string}>({});
  const [loading, setLoading] = useState(false);

  const validateForm = () => {
    const newErrors: {[key: string]: string} = {};
    
    if (!formData.make?.trim()) {
      newErrors.make = 'Make is required';
    }
    
    if (!formData.model?.trim()) {
      newErrors.model = 'Model is required';
    }
    
    if (!formData.year || formData.year < 1900 || formData.year > new Date().getFullYear() + 1) {
      newErrors.year = 'Please enter a valid year';
    }
    
    if (!formData.color?.trim()) {
      newErrors.color = 'Color is required';
    }
    
    if (!formData.plateNumber?.trim()) {
      newErrors.plateNumber = 'Plate number is required';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSave = async () => {
    if (!validateForm()) return;
    
    setLoading(true);
    try {
      // TODO: Implement car creation API call
      console.log('Creating car:', formData);
      
      // For now, just show success and navigate to session creation
      Alert.alert(
        'Car Added',
        'Vehicle has been registered successfully. Now create a session.',
        [
          {
            text: 'Create Session',
            onPress: () => {
              // TODO: Navigate to create session screen with customer and car IDs
              console.log('Navigate to create session screen');
            }
          }
        ]
      );
    } catch (error) {
      Alert.alert('Error', 'Failed to register vehicle');
    } finally {
      setLoading(false);
    }
  };

  const updateField = (field: keyof CreateCarData, value: string | number) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.scrollView}>
        <View style={styles.header}>
          <Text style={styles.title}>Add Car</Text>
          <Text style={styles.subtitle}>
            {customerName ? `Register vehicle for ${customerName}` : 'Register new vehicle'}
          </Text>
        </View>

        <View style={styles.form}>
          <Input
            label="Make *"
            value={formData.make || ''}
            onChangeText={(value) => updateField('make', value)}
            placeholder="Toyota, BMW, Mercedes..."
            error={errors.make}
            leftIcon={<Text style={styles.icon}>🚗</Text>}
          />

          <Input
            label="Model *"
            value={formData.model || ''}
            onChangeText={(value) => updateField('model', value)}
            placeholder="Camry, X5, C-Class..."
            error={errors.model}
            leftIcon={<Text style={styles.icon}>🔧</Text>}
          />

          <Input
            label="Year *"
            value={formData.year?.toString() || ''}
            onChangeText={(value) => updateField('year', parseInt(value) || new Date().getFullYear())}
            placeholder="2024"
            keyboardType="numeric"
            error={errors.year}
            leftIcon={<Text style={styles.icon}>📅</Text>}
          />

          <Input
            label="Color *"
            value={formData.color || ''}
            onChangeText={(value) => updateField('color', value)}
            placeholder="White, Black, Silver..."
            error={errors.color}
            leftIcon={<Text style={styles.icon}>🎨</Text>}
          />

          <Input
            label="Plate Number *"
            value={formData.plateNumber || ''}
            onChangeText={(value) => updateField('plateNumber', value.toUpperCase())}
            placeholder="A 12345"
            autoCapitalize="characters"
            error={errors.plateNumber}
            leftIcon={<Text style={styles.icon}>🏷️</Text>}
          />

          <Input
            label="Emirate"
            value={formData.emirate || ''}
            onChangeText={(value) => updateField('emirate', value)}
            placeholder="Dubai, Abu Dhabi, Sharjah..."
            leftIcon={<Text style={styles.icon}>🏛️</Text>}
          />

          <Input
            label="VIN"
            value={formData.vin || ''}
            onChangeText={(value) => updateField('vin', value.toUpperCase())}
            placeholder="Vehicle Identification Number"
            autoCapitalize="characters"
            leftIcon={<Text style={styles.icon}>🔍</Text>}
          />

          <Input
            label="Current Mileage"
            value={formData.currentMileage?.toString() || ''}
            onChangeText={(value) => updateField('currentMileage', parseInt(value) || 0)}
            placeholder="120000"
            keyboardType="numeric"
            leftIcon={<Text style={styles.icon}>⏱️</Text>}
          />

          <Input
            label="Notes"
            value={formData.notes || ''}
            onChangeText={(value) => updateField('notes', value)}
            placeholder="Additional vehicle information"
            multiline
            leftIcon={<Text style={styles.icon}>📝</Text>}
          />

          <Button
            title="Register Car & Create Session"
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
  saveButton: {
    marginTop: theme.spacing.lg,
  },
});