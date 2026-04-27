class Note {
  const Note({
    required this.id,
    required this.title,
    required this.rawTranscript,
    required this.formattedNoteMarkdown,
    required this.createdAt,
    required this.eventTitle,
    required this.eventDate,
    required this.eventCreated,
  });

  final int? id;
  final String title;
  final String rawTranscript;
  final String formattedNoteMarkdown;
  final DateTime createdAt;
  final String? eventTitle;
  final DateTime? eventDate;
  final bool eventCreated;

  Note copyWith({
    int? id,
    String? title,
    String? rawTranscript,
    String? formattedNoteMarkdown,
    DateTime? createdAt,
    String? eventTitle,
    DateTime? eventDate,
    bool? eventCreated,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      rawTranscript: rawTranscript ?? this.rawTranscript,
      formattedNoteMarkdown: formattedNoteMarkdown ?? this.formattedNoteMarkdown,
      createdAt: createdAt ?? this.createdAt,
      eventTitle: eventTitle ?? this.eventTitle,
      eventDate: eventDate ?? this.eventDate,
      eventCreated: eventCreated ?? this.eventCreated,
    );
  }

  Map<String, Object?> toDbMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'raw_transcript': rawTranscript,
      'formatted_note_md': formattedNoteMarkdown,
      'created_at': createdAt.toIso8601String(),
      'event_title': eventTitle,
      'event_date': eventDate?.toIso8601String(),
      'event_created': eventCreated ? 1 : 0,
    };
  }

  static Note fromDbMap(Map<String, Object?> map) {
    return Note(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      rawTranscript: (map['raw_transcript'] as String?) ?? '',
      formattedNoteMarkdown: (map['formatted_note_md'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      eventTitle: map['event_title'] as String?,
      eventDate:
          map['event_date'] == null ? null : DateTime.parse(map['event_date'] as String),
      eventCreated: (map['event_created'] as int? ?? 0) == 1,
    );
  }
}

