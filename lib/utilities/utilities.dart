String extractUsername(String email) {
  final regex = RegExp(r'^([^@]+)@');
  final match = regex.firstMatch(email);
  if (match != null) {
    return match.group(1)!;
  }
  return '';
}
