String deriveNoteTitle({required String formattedMarkdown, String? eventTitle}) {
  final trimmedEvent = eventTitle?.trim();
  if (trimmedEvent != null && trimmedEvent.isNotEmpty) return trimmedEvent;

  final lines = formattedMarkdown.split('\n');
  for (final line in lines) {
    final cleaned = line
        .trim()
        .replaceAll(RegExp(r'^#+\s*'), '')
        .replaceAll(RegExp(r'[*_`~]'), '');
    if (cleaned.isNotEmpty) {
      return cleaned.length <= 60 ? cleaned : '${cleaned.substring(0, 60)}…';
    }
  }

  final fallback = formattedMarkdown.trim();
  if (fallback.isEmpty) return 'Untitled';
  return fallback.length <= 60 ? fallback : '${fallback.substring(0, 60)}…';
}

String stripCodeFences(String text) {
  final trimmed = text.trim();
  final fenced = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$', caseSensitive: false);
  final match = fenced.firstMatch(trimmed);
  if (match == null) return trimmed;
  return (match.group(1) ?? '').trim();
}

