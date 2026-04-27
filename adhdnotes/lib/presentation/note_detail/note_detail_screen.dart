import 'package:adhdnotes/data/models/note.dart';
import 'package:adhdnotes/presentation/providers/notes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NoteDetailScreen extends StatelessWidget {
  const NoteDetailScreen({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: note.id == null
                ? null
                : () async {
                    await context.read<NotesProvider>().deleteById(note.id!);
                    if (context.mounted) Navigator.of(context).pop();
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Created: ${dateFormat.format(note.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (note.eventDate != null)
              _EventCard(
                title: note.eventTitle ?? 'Event',
                dateTime: note.eventDate!,
                created: note.eventCreated,
              ),
            if (note.eventDate != null) const SizedBox(height: 16),
            MarkdownBody(data: note.formattedNoteMarkdown),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.title,
    required this.dateTime,
    required this.created,
  });

  final String title;
  final DateTime dateTime;
  final bool created;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.event),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(dateFormat.format(dateTime)),
                if (created) const SizedBox(height: 4),
                if (created) const Text('Added to calendar'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

