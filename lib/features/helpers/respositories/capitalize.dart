String capitalize(String text) {
  final firstletter = text.substring(0, 1).toUpperCase();
  final rest = text.substring(1);
  return '$firstletter$rest';
}
