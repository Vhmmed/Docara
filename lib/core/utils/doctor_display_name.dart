String toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

String doctorDisplayName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return 'Dr.';
  final trimmed = fullName.trim();
  final lower = trimmed.toLowerCase();
  if (lower.startsWith('dr.') || lower.startsWith('dr ')) {
    return toTitleCase(trimmed);
  }
  return 'Dr. ${toTitleCase(trimmed)}';
}
