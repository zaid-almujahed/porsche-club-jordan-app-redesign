abstract final class AppFormatters {
  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String money(double amount, String currency) {
    return '${amount.toStringAsFixed(2)} $currency';
  }

  /// "CASH" -> "Cash"; "CLIQ" -> "CliQ".
  static String paymentMethod(String value) =>
      value.trim().toUpperCase() == 'CLIQ' ? 'CliQ' : initCap(value);

  static String initCap(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty ||
        RegExp(r'^#?[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$').hasMatch(trimmed)) {
      return trimmed;
    }
    return trimmed.toLowerCase().replaceAllMapped(
      RegExp(r'(^|[\s\-/])([a-z])'),
      (Match match) =>
          '${match.group(1) ?? ''}${match.group(2)!.toUpperCase()}',
    );
  }

  static String date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')} '
        '${_months[value.month - 1]}, ${value.year}';
  }

  /// "29/09/2026" (DD/MM/YYYY).
  static String numericDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  /// "October 2026".
  static String monthYear(DateTime value) {
    return '${_monthNames[value.month - 1]} ${value.year}';
  }

  static String time(DateTime value) {
    final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final String minute = value.minute.toString().padLeft(2, '0');
    final String period = value.hour < 12 ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  static String dateAndTime(DateTime value) {
    return '${date(value)} · ${time(value)}';
  }

  /// "02:30 PM - 06:00 PM", or just "02:30 PM" when there is no later end
  /// time (events currently only have a start time).
  static String timeRange(DateTime start, DateTime end) {
    if (!end.isAfter(start)) return time(start);
    return '${time(start)} - ${time(end)}';
  }
}
