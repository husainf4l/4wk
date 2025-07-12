import { ValidationError, ValidationResult } from '../../types/api';

export type ValidationRule<T = any> = {
  field: keyof T;
  rules: Array<{
    type: 'required' | 'email' | 'phone' | 'minLength' | 'maxLength' | 'pattern' | 'custom';
    value?: any;
    message: string;
    validator?: (value: any, data: T) => boolean;
  }>;
};

export class ValidationService {
  /**
   * Validate a single field
   */
  static validateField<T>(
    fieldName: keyof T,
    value: any,
    rules: ValidationRule<T>['rules'],
    data?: T
  ): ValidationError[] {
    const errors: ValidationError[] = [];

    for (const rule of rules) {
      let isValid = true;
      
      switch (rule.type) {
        case 'required':
          isValid = this.validateRequired(value);
          break;
          
        case 'email':
          isValid = this.validateEmail(value);
          break;
          
        case 'phone':
          isValid = this.validatePhone(value);
          break;
          
        case 'minLength':
          isValid = this.validateMinLength(value, rule.value);
          break;
          
        case 'maxLength':
          isValid = this.validateMaxLength(value, rule.value);
          break;
          
        case 'pattern':
          isValid = this.validatePattern(value, rule.value);
          break;
          
        case 'custom':
          isValid = rule.validator ? rule.validator(value, data) : true;
          break;
          
        default:
          break;
      }

      if (!isValid) {
        errors.push({
          field: fieldName as string,
          message: rule.message,
          value,
        });
      }
    }

    return errors;
  }

  /**
   * Validate an entire object
   */
  static validateObject<T>(data: T, validationRules: ValidationRule<T>[]): ValidationResult {
    const errors: ValidationError[] = [];

    for (const rule of validationRules) {
      const fieldValue = data[rule.field];
      const fieldErrors = this.validateField(rule.field, fieldValue, rule.rules, data);
      errors.push(...fieldErrors);
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  /**
   * Validate required field
   */
  private static validateRequired(value: any): boolean {
    if (value === null || value === undefined) {
      return false;
    }
    
    if (typeof value === 'string') {
      return value.trim().length > 0;
    }
    
    if (Array.isArray(value)) {
      return value.length > 0;
    }
    
    return true;
  }

  /**
   * Validate email format
   */
  private static validateEmail(value: any): boolean {
    if (!value) return true; // Allow empty for optional fields
    
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(value);
  }

  /**
   * Validate phone number format
   */
  private static validatePhone(value: any): boolean {
    if (!value) return true; // Allow empty for optional fields
    
    // UAE phone number patterns
    const phoneRegex = /^(\+971|00971|971)?[\s-]?[0-9][\s-]?[0-9]{7,8}$/;
    const cleanPhone = value.replace(/[\s-()]/g, '');
    
    return phoneRegex.test(cleanPhone);
  }

  /**
   * Validate minimum length
   */
  private static validateMinLength(value: any, minLength: number): boolean {
    if (!value) return true; // Allow empty for optional fields
    
    return value.toString().length >= minLength;
  }

  /**
   * Validate maximum length
   */
  private static validateMaxLength(value: any, maxLength: number): boolean {
    if (!value) return true; // Allow empty for optional fields
    
    return value.toString().length <= maxLength;
  }

  /**
   * Validate against regex pattern
   */
  private static validatePattern(value: any, pattern: RegExp): boolean {
    if (!value) return true; // Allow empty for optional fields
    
    return pattern.test(value.toString());
  }

  /**
   * Get customer validation rules
   */
  static getCustomerValidationRules() {
    return [
      {
        field: 'name' as const,
        rules: [
          {
            type: 'required' as const,
            message: 'Customer name is required',
          },
          {
            type: 'minLength' as const,
            value: 2,
            message: 'Name must be at least 2 characters long',
          },
          {
            type: 'maxLength' as const,
            value: 100,
            message: 'Name must be less than 100 characters',
          },
        ],
      },
      {
        field: 'phone' as const,
        rules: [
          {
            type: 'required' as const,
            message: 'Phone number is required',
          },
          {
            type: 'phone' as const,
            message: 'Please enter a valid UAE phone number',
          },
        ],
      },
      {
        field: 'email' as const,
        rules: [
          {
            type: 'email' as const,
            message: 'Please enter a valid email address',
          },
        ],
      },
      {
        field: 'companyName' as const,
        rules: [
          {
            type: 'custom' as const,
            message: 'Company name is required when customer is a company',
            validator: (value: any, data: any) => {
              if (data?.isCompany && !value?.trim()) {
                return false;
              }
              return true;
            },
          },
        ],
      },
    ];
  }

  /**
   * Get car validation rules
   */
  static getCarValidationRules() {
    return [
      {
        field: 'make' as const,
        rules: [
          {
            type: 'required' as const,
            message: 'Car make is required',
          },
          {
            type: 'minLength' as const,
            value: 2,
            message: 'Make must be at least 2 characters long',
          },
        ],
      },
      {
        field: 'model' as const,
        rules: [
          {
            type: 'required' as const,
            message: 'Car model is required',
          },
          {
            type: 'minLength' as const,
            value: 1,
            message: 'Model is required',
          },
        ],
      },
      {
        field: 'year' as const,
        rules: [
          {
            type: 'required' as const,
            message: 'Year is required',
          },
          {
            type: 'custom' as const,
            message: 'Please enter a valid year',
            validator: (value: any) => {
              const year = parseInt(value);
              const currentYear = new Date().getFullYear();
              return year >= 1900 && year <= currentYear + 1;
            },
          },
        ],
      },
      {
        field: 'color' as const,
        rules: [
          {
            type: 'required' as const,
            message: 'Color is required',
          },
        ],
      },
      {
        field: 'plateNumber' as const,
        rules: [
          {
            type: 'required' as const,
            message: 'Plate number is required',
          },
          {
            type: 'pattern' as const,
            value: /^[A-Z0-9\s]+$/,
            message: 'Plate number can only contain letters, numbers, and spaces',
          },
        ],
      },
      {
        field: 'vin' as const,
        rules: [
          {
            type: 'pattern' as const,
            value: /^[A-HJ-NPR-Z0-9]{17}$/,
            message: 'VIN must be exactly 17 characters (letters and numbers, excluding I, O, Q)',
          },
        ],
      },
    ];
  }

  /**
   * Get session validation rules
   */
  static getSessionValidationRules() {
    return [
      {
        field: 'customerId' as const,
        rules: [
          {
            type: 'required' as const,
            message: 'Customer is required',
          },
        ],
      },
      {
        field: 'carId' as const,
        rules: [
          {
            type: 'required' as const,
            message: 'Car is required',
          },
        ],
      },
      {
        field: 'customerRequests' as const,
        rules: [
          {
            type: 'custom' as const,
            message: 'At least one customer request is required',
            validator: (value: any) => {
              if (!Array.isArray(value)) return false;
              return value.length > 0 && value.some(request => request?.trim());
            },
          },
        ],
      },
      {
        field: 'initialMileage' as const,
        rules: [
          {
            type: 'required' as const,
            message: 'Current mileage is required',
          },
          {
            type: 'custom' as const,
            message: 'Mileage must be a positive number',
            validator: (value: any) => {
              const mileage = parseInt(value);
              return !isNaN(mileage) && mileage >= 0;
            },
          },
        ],
      },
    ];
  }

  /**
   * Get user validation rules
   */
  static getUserValidationRules() {
    return [
      {
        field: 'firstName' as const,
        rules: [
          {
            type: 'required' as const,
            message: 'First name is required',
          },
          {
            type: 'minLength' as const,
            value: 2,
            message: 'First name must be at least 2 characters long',
          },
        ],
      },
      {
        field: 'lastName' as const,
        rules: [
          {
            type: 'required' as const,
            message: 'Last name is required',
          },
          {
            type: 'minLength' as const,
            value: 2,
            message: 'Last name must be at least 2 characters long',
          },
        ],
      },
      {
        field: 'email' as const,
        rules: [
          {
            type: 'required' as const,
            message: 'Email is required',
          },
          {
            type: 'email' as const,
            message: 'Please enter a valid email address',
          },
        ],
      },
      {
        field: 'role' as const,
        rules: [
          {
            type: 'required' as const,
            message: 'Role is required',
          },
        ],
      },
    ];
  }

  /**
   * Validate file upload
   */
  static validateFile(file: any, options: {
    maxSize?: number;
    allowedTypes?: string[];
    required?: boolean;
  } = {}): ValidationResult {
    const errors: ValidationError[] = [];

    if (options.required && !file) {
      errors.push({
        field: 'file',
        message: 'File is required',
      });
      return { isValid: false, errors };
    }

    if (!file) {
      return { isValid: true, errors: [] };
    }

    // Check file size
    if (options.maxSize && file.size > options.maxSize) {
      errors.push({
        field: 'file',
        message: `File size must be less than ${options.maxSize / 1024 / 1024}MB`,
        value: file.size,
      });
    }

    // Check file type
    if (options.allowedTypes && options.allowedTypes.length > 0) {
      const extension = file.name?.toLowerCase().split('.').pop();
      if (!extension || !options.allowedTypes.includes(extension)) {
        errors.push({
          field: 'file',
          message: `File type must be one of: ${options.allowedTypes.join(', ')}`,
          value: extension,
        });
      }
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }
}

export const validationService = ValidationService;