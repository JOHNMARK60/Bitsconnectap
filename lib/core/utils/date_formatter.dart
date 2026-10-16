import 'package:intl/intl.dart';

class DateFormatter {
  static String date(String? value) {
    if (value == null || value.isEmpty) return 'Not set';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('MMM d, yyyy').format(parsed);
  }

  static String dateTime(String? value) {
    if (value == null || value.isEmpty) return 'Not set';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('MMM d, yyyy h:mm a').format(parsed);
  }
}
