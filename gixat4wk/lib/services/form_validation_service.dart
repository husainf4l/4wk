// /// A service class providing common form validation functions
// class FormValidationService {
//   /// Validates that a field is not empty
//   static String? validateRequired(String? value, {String? fieldName}) {
//     if (value == null || value.trim().isEmpty) {
//       return '${fieldName ?? 'This field'} is required';
//     }
//     return null;
//   }

//   /// Validates a valid email format
//   static String? validateEmail(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return 'Email is required';
//     }

//     final emailRegEx = RegExp(
//       r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
//     );

//     if (!emailRegEx.hasMatch(value)) {
//       return 'Please enter a valid email address';
//     }

//     return null;
//   }

//   /// Validates a phone number
//   static String? validatePhone(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return null; // Phone can be optional
//     }

//     // Remove any non-digit characters for validation
//     final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

//     if (digitsOnly.length < 10) {
//       return 'Phone number must have at least 10 digits';
//     }

//     return null;
//   }

//   /// Validates a password with minimum criteria
//   static String? validatePassword(String? value, {int minLength = 8}) {
//     if (value == null || value.isEmpty) {
//       return 'Password is required';
//     }

//     if (value.length < minLength) {
//       return 'Password must be at least $minLength characters';
//     }

//     return null;
//   }

//   /// Validates that two passwords match
//   static String? validatePasswordMatch(
//     String? password,
//     String? confirmPassword,
//   ) {
//     if (confirmPassword == null || confirmPassword.isEmpty) {
//       return 'Please confirm your password';
//     }

//     if (password != confirmPassword) {
//       return 'Passwords do not match';
//     }

//     return null;
//   }

//   /// Validates a number within a specific range
//   static String? validateNumberRange(
//     String? value, {
//     double? min,
//     double? max,
//     bool allowDecimal = true,
//     String? fieldName,
//   }) {
//     if (value == null || value.isEmpty) {
//       return null; // Allow empty if needed
//     }

//     // Check if the input is a valid number
//     final number = allowDecimal ? double.tryParse(value) : int.tryParse(value);

//     if (number == null) {
//       return '${fieldName ?? 'This field'} must be a valid number';
//     }

//     if (min != null && number < min) {
//       return '${fieldName ?? 'This field'} must be at least $min';
//     }

//     if (max != null && number > max) {
//       return '${fieldName ?? 'This field'} must be at most $max';
//     }

//     if (!allowDecimal && double.parse(value) != number) {
//       return '${fieldName ?? 'This field'} must be a whole number';
//     }

//     return null;
//   }

//   /// Validates the length of text input
//   static String? validateTextLength(
//     String? value, {
//     int? minLength,
//     int? maxLength,
//     String? fieldName,
//   }) {
//     if (value == null || value.isEmpty) {
//       return null; // Allow empty if needed
//     }

//     if (minLength != null && value.length < minLength) {
//       return '${fieldName ?? 'This field'} must be at least $minLength characters';
//     }

//     if (maxLength != null && value.length > maxLength) {
//       return '${fieldName ?? 'This field'} must be at most $maxLength characters';
//     }

//     return null;
//   }

//   /// Validates a date is within a specific range
//   static String? validateDateRange(
//     DateTime? value, {
//     DateTime? minDate,
//     DateTime? maxDate,
//     String? fieldName,
//   }) {
//     if (value == null) {
//       return null; // Allow null if needed
//     }

//     if (minDate != null && value.isBefore(minDate)) {
//       return '${fieldName ?? 'Date'} cannot be before ${_formatDate(minDate)}';
//     }

//     if (maxDate != null && value.isAfter(maxDate)) {
//       return '${fieldName ?? 'Date'} cannot be after ${_formatDate(maxDate)}';
//     }

//     return null;
//   }

//   /// Helper function to format a date for error messages
//   static String _formatDate(DateTime date) {
//     return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
//   }

//   /// Validates a car VIN number
//   static String? validateVIN(String? value) {
//     if (value == null || value.isEmpty) {
//       return null; // VIN can be optional
//     }

//     // Basic VIN validation (most VINs are 17 characters)
//     if (value.length != 17) {
//       return 'VIN should be 17 characters';
//     }

//     // Check for invalid characters
//     if (RegExp(r'[IOQ]').hasMatch(value)) {
//       return 'VIN should not contain I, O, or Q';
//     }

//     return null;
//   }

//   /// Validates a license plate
//   static String? validateLicensePlate(String? value) {
//     if (value == null || value.isEmpty) {
//       return null; // License plate can be optional
//     }

//     // License plate format varies by region, this is a simple check
//     if (value.length < 2 || value.length > 10) {
//       return 'Please enter a valid license plate';
//     }

//     return null;
//   }
// }
