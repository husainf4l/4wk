import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  Alert,
  TouchableOpacity,
} from 'react-native';
import { theme } from '../../styles/theme';
import { Button } from '../../components/Button';
import { Input } from '../../components/Input';
import { CreateSessionData } from '../../types/Session';

interface CreateSessionScreenProps {
  customerId?: string;
  customerName?: string;
  carId?: string;
  carInfo?: string; // e.g., "Toyota Camry 2020"
}

export const CreateSessionScreen: React.FC<CreateSessionScreenProps> = ({ 
  customerId, 
  customerName,
  carId,
  carInfo
}) => {
  const [formData, setFormData] = useState<Partial<CreateSessionData>>({
    customerId: customerId || '',
    carId: carId || '',
    customerRequests: [''],
    initialMileage: 0,
    initialNotes: '',
    priority: 'normal',
    estimatedCompletionTime: 2,
  });
  const [errors, setErrors] = useState<{[key: string]: string}>({});
  const [loading, setLoading] = useState(false);

  const validateForm = () => {
    const newErrors: {[key: string]: string} = {};
    
    if (!formData.customerId) {
      newErrors.customer = 'Customer is required';
    }
    
    if (!formData.carId) {
      newErrors.car = 'Car is required';
    }
    
    if (!formData.customerRequests || formData.customerRequests.length === 0 || !formData.customerRequests[0]) {
      newErrors.requests = 'At least one customer request is required';
    }
    
    if (!formData.initialMileage || formData.initialMileage < 0) {
      newErrors.mileage = 'Current mileage is required';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSave = async () => {
    if (!validateForm()) return;
    
    setLoading(true);
    try {
      // TODO: Implement session creation API call
      console.log('Creating session:', formData);
      
      // For now, just show success
      Alert.alert(
        'Session Created',
        'Service session has been created successfully. You can now start the inspection and test drive.',
        [
          {
            text: 'Start Inspection',
            onPress: () => {
              // TODO: Navigate to inspection screen
              console.log('Navigate to inspection screen');
            }
          },
          {
            text: 'Later',
            style: 'cancel'
          }
        ]
      );
    } catch (error) {
      Alert.alert('Error', 'Failed to create session');
    } finally {
      setLoading(false);
    }
  };

  const updateField = (field: keyof CreateSessionData, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  const addRequest = () => {
    const requests = formData.customerRequests || [];
    updateField('customerRequests', [...requests, '']);
  };

  const updateRequest = (index: number, value: string) => {
    const requests = [...(formData.customerRequests || [])];
    requests[index] = value;
    updateField('customerRequests', requests);
  };

  const removeRequest = (index: number) => {
    const requests = formData.customerRequests || [];
    if (requests.length > 1) {
      const newRequests = requests.filter((_, i) => i !== index);
      updateField('customerRequests', newRequests);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.scrollView}>
        <View style={styles.header}>
          <Text style={styles.title}>Create Session</Text>
          <Text style={styles.subtitle}>
            {customerName && carInfo ? 
              `New session for ${customerName} - ${carInfo}` : 
              'Start new service session'
            }
          </Text>
        </View>

        <View style={styles.form}>
          {/* Customer Requests */}
          <View style={styles.sectionContainer}>
            <Text style={styles.sectionTitle}>Customer Requests/Complaints</Text>
            {(formData.customerRequests || ['']).map((request, index) => (
              <View key={index} style={styles.requestContainer}>
                <Input
                  label={`Request ${index + 1} *`}
                  value={request}
                  onChangeText={(value) => updateRequest(index, value)}
                  placeholder="Describe the customer's request or complaint"
                  multiline
                  containerStyle={styles.requestInput}
                />
                {index > 0 && (
                  <TouchableOpacity 
                    style={styles.removeButton}
                    onPress={() => removeRequest(index)}
                  >
                    <Text style={styles.removeButtonText}>✕</Text>
                  </TouchableOpacity>
                )}
              </View>
            ))}
            
            <Button
              title="+ Add Another Request"
              onPress={addRequest}
              variant="outline"
              size="small"
              style={styles.addButton}
            />
            
            {errors.requests && (
              <Text style={styles.errorText}>{errors.requests}</Text>
            )}
          </View>

          <Input
            label="Current Mileage *"
            value={formData.initialMileage?.toString() || ''}
            onChangeText={(value) => updateField('initialMileage', parseInt(value) || 0)}
            placeholder="Enter current odometer reading"
            keyboardType="numeric"
            error={errors.mileage}
            leftIcon={<Text style={styles.icon}>⏱️</Text>}
          />

          <Input
            label="Initial Notes"
            value={formData.initialNotes || ''}
            onChangeText={(value) => updateField('initialNotes', value)}
            placeholder="Any initial observations or notes"
            multiline
            leftIcon={<Text style={styles.icon}>📝</Text>}
          />

          <Input
            label="Estimated Completion Time (hours)"
            value={formData.estimatedCompletionTime?.toString() || ''}
            onChangeText={(value) => updateField('estimatedCompletionTime', parseInt(value) || 2)}
            placeholder="2"
            keyboardType="numeric"
            leftIcon={<Text style={styles.icon}>⏰</Text>}
          />

          {/* Priority Selection */}
          <View style={styles.priorityContainer}>
            <Text style={styles.inputLabel}>Priority</Text>
            <View style={styles.priorityButtons}>
              {(['low', 'normal', 'high', 'urgent'] as const).map((priority) => (
                <TouchableOpacity
                  key={priority}
                  style={[
                    styles.priorityButton,
                    formData.priority === priority && styles.priorityButtonActive
                  ]}
                  onPress={() => updateField('priority', priority)}
                >
                  <Text style={[
                    styles.priorityButtonText,
                    formData.priority === priority && styles.priorityButtonTextActive
                  ]}>
                    {priority.charAt(0).toUpperCase() + priority.slice(1)}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          <Button
            title="Create Session & Start Inspection"
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
  sectionContainer: {
    marginBottom: theme.spacing.lg,
  },
  sectionTitle: {
    fontSize: theme.fonts.sizes.lg,
    fontWeight: theme.fonts.weights.semibold,
    color: theme.colors.text,
    marginBottom: theme.spacing.md,
  },
  requestContainer: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: theme.spacing.sm,
  },
  requestInput: {
    flex: 1,
  },
  removeButton: {
    marginLeft: theme.spacing.sm,
    marginTop: theme.spacing.lg,
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: theme.colors.error,
    alignItems: 'center',
    justifyContent: 'center',
  },
  removeButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: 'bold',
  },
  addButton: {
    marginTop: theme.spacing.sm,
  },
  errorText: {
    fontSize: theme.fonts.sizes.xs,
    color: theme.colors.error,
    marginTop: theme.spacing.xs,
  },
  inputLabel: {
    fontSize: theme.fonts.sizes.sm,
    fontWeight: theme.fonts.weights.medium,
    color: theme.colors.text,
    marginBottom: theme.spacing.sm,
  },
  priorityContainer: {
    marginBottom: theme.spacing.lg,
  },
  priorityButtons: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  priorityButton: {
    flex: 1,
    padding: theme.spacing.md,
    marginHorizontal: theme.spacing.xs,
    borderRadius: theme.borderRadius.medium,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.surface,
    alignItems: 'center',
  },
  priorityButtonActive: {
    backgroundColor: theme.colors.primary,
    borderColor: theme.colors.primary,
  },
  priorityButtonText: {
    fontSize: theme.fonts.sizes.sm,
    color: theme.colors.text,
    fontWeight: theme.fonts.weights.medium,
  },
  priorityButtonTextActive: {
    color: '#FFFFFF',
  },
  saveButton: {
    marginTop: theme.spacing.xl,
  },
});