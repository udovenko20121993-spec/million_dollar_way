import 'package:intl/intl.dart';

class FormattingUtils {
  static String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
  }

  static String formatCurrency(double amount) {
    final formatter = NumberFormat.decimalPatternDigits(decimalDigits: 2);
    return formatter.format(amount);
  }

  static String formatCurrencyUAH(double amount) {
    final formatter = NumberFormat.decimalPatternDigits(decimalDigits: 2);
    return formatter.format(amount);
  }

  static String formatPercent(double percent) {
    final formatter = NumberFormat.percentPattern();
    return formatter.format(percent / 100);
  }

  static String formatNumber(double number) {
    final formatter = NumberFormat.decimalPatternDigits(decimalDigits: 0);
    return formatter.format(number);
  }
}
