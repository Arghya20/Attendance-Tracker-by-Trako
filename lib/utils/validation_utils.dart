/// A utility class for form validation
class ValidationUtils {
  /// Validate a required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  /// Validate a field with minimum length
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }
  
  /// Validate a field with maximum length
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return null; // Not required
    }
    if (value.trim().length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    return null;
  }
  
  /// Validate a field with minimum and maximum length
  static String? validateLength(
    String? value,
    int minLength,
    int maxLength,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    if (value.trim().length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    return null;
  }
  
  /// Validate a date field
  static String? validateDate(DateTime? value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }
    return null;
  }
  
  /// Validate a date range
  static String? validateDateRange(
    DateTime? startDate,
    DateTime? endDate,
    String startFieldName,
    String endFieldName,
  ) {
    if (startDate == null) {
      return '$startFieldName is required';
    }
    if (endDate == null) {
      return '$endFieldName is required';
    }
    if (endDate.isBefore(startDate)) {
      return '$endFieldName must be after $startFieldName';
    }
    return null;
  }
  
  /// Validate a number field
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (double.tryParse(value) == null) {
      return '$fieldName must be a number';
    }
    return null;
  }
  
  /// Validate a number range
  static String? validateNumberRange(
    String? value,
    double min,
    double max,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName must be a number';
    }
    if (number < min) {
      return '$fieldName must be at least $min';
    }
    if (number > max) {
      return '$fieldName cannot exceed $max';
    }
    return null;
  }
}