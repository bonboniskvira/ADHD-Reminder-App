class DeepSeekNoteFormatResult {
  const DeepSeekNoteFormatResult({
    required this.noteMarkdown,
    required this.eventTitle,
    required this.eventDate,
  });

  final String noteMarkdown;
  final String? eventTitle;
  final DateTime? eventDate;
}

