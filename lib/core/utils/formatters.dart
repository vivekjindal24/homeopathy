import 'package:intl/intl.dart';

/// Date and number formatting helpers used throughout the app.
class AppFormatters {
  AppFormatters._();

  static final _dateShort = DateFormat('dd MMM yyyy');
  static final _dateLong = DateFormat('EEEE, dd MMMM yyyy');
  static final _time12 = DateFormat('hh:mm a');
  static final _time24 = DateFormat('HH:mm');
  static final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final _monthYear = DateFormat('MMMM yyyy');
  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  static final _compact = NumberFormat.compact(locale: 'en_IN');
  static final _decimal = NumberFormat('#,##,##0.00', 'en_IN');

  /// Format a [DateTime] as "25 Jan 2024".
  static String dateShort(DateTime? date) =>
      date == null ? '--' : _dateShort.format(date);

  /// Format a [DateTime] as "Monday, 25 January 2024".
  static String dateLong(DateTime? date) =>
      date == null ? '--' : _dateLong.format(date);

  /// Format a [DateTime] as "02:30 PM".
  static String time12(DateTime? date) =>
      date == null ? '--' : _time12.format(date);

  /// Format a [DateTime] as "14:30".
  static String time24(DateTime? date) =>
      date == null ? '--' : _time24.format(date);

  /// Format a [DateTime] as "25 Jan 2024, 02:30 PM".
  static String dateTime(DateTime? date) =>
      date == null ? '--' : _dateTime.format(date);

  /// Format a [DateTime] as "January 2024".
  static String monthYear(DateTime? date) =>
      date == null ? '--' : _monthYear.format(date);

  /// Format a number as Indian Rupee: "₹1,25,000.00".
  static String currency(num? amount) =>
      amount == null ? '₹--' : _currency.format(amount);

  /// Format a number compactly: "1.25K", "2.4M".
  static String compact(num? value) =>
      value == null ? '--' : _compact.format(value);

  /// Format a decimal with commas: "1,25,000.00".
  static String decimal(num? value) =>
      value == null ? '--' : _decimal.format(value);

  /// Format a phone number for display: "+91 98765 43210".
  static String phone(String? raw) {
    if (raw == null || raw.isEmpty) return '--';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return raw;
  }

  /// Age from date of birth.
  static String age(DateTime? dob) {
    if (dob == null) return '--';
    final now = DateTime.now();
    final years = now.year -
        dob.year -
        (now.month < dob.month ||
                (now.month == dob.month && now.day < dob.day)
            ? 1
            : 0);
    return '$years yrs';
  }

  /// Format BP as "120/80 mmHg".
  static String bloodPressure(int? systolic, int? diastolic) {
    if (systolic == null || diastolic == null) return '--';
    return '$systolic/$diastolic mmHg';
  }

  /// Format weight as "72.5 kg".
  static String weight(double? kg) => kg == null ? '--' : '${kg.toStringAsFixed(1)} kg';

  /// Format SpO2 as "98%".
  static String spo2(int? value) => value == null ? '--' : '$value%';

  /// Format temperature as "36.8 °C".
  static String temperature(double? value) =>
      value == null ? '--' : '${value.toStringAsFixed(1)} °C';
}

