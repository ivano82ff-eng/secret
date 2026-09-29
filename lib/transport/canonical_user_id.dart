/// Matches server contract `^[0-9]{3} [A-Z] [0-9]{3}$`.
String? canonicalizeUserId(String input) {
  final collapsed = input.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
  if (!RegExp(r'^[0-9]{3} [A-Z] [0-9]{3}$').hasMatch(collapsed)) {
    return null;
  }
  return collapsed;
}

String encodeUserIdPathSegment(String canonicalUserId) {
  return Uri.encodeComponent(canonicalUserId);
}
