/// Form field validators used across all screens.
class AppValidators {
  AppValidators._();

  /// Required field — must not be null or empty.
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Email format validator.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  /// Indian mobile number (10 digits).
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Enter a valid 10-digit mobile number';
    return null;
  }

  /// Password: minimum 8 chars with at least one letter and one digit.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Password must contain at least one letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// 6-digit OTP.
  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) return 'OTP is required';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Enter a valid 6-digit OTP';
    }
    return null;
  }

  /// Positive number (weight, SpO2, etc.).
  static String? positiveNumber(String? value, [String label = 'Value']) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return '$label must be positive';
    return null;
  }

  /// Blood pressure systolic (50–250).
  static String? bpSystolic(String? value) {
    final err = positiveNumber(value, 'Systolic BP');
    if (err != null) return err;
    final n = int.tryParse(value!.trim())!;
    if (n < 50 || n > 250) return 'Systolic BP must be between 50–250';
    return null;
  }

  /// Blood pressure diastolic (30–150).
  static String? bpDiastolic(String? value) {
    final err = positiveNumber(value, 'Diastolic BP');
    if (err != null) return err;
    final n = int.tryParse(value!.trim())!;
    if (n < 30 || n > 150) return 'Diastolic BP must be between 30–150';
    return null;
  }

  /// SpO2 (1–100).
  static String? spo2(String? value) {
    final err = positiveNumber(value, 'SpO2');
    if (err != null) return err;
    final n = int.tryParse(value!.trim())!;
    if (n < 1 || n > 100) return 'SpO2 must be between 1–100%';
    return null;
  }

  /// Combines multiple validators — runs each in sequence.
  static String? Function(String?) combine(
      List<String? Function(String?)> validators) {
    return (value) {
      for (final v in validators) {
        final err = v(value);
        if (err != null) return err;
      }
      return null;
    };
  }
}

