import 'package:adhdnotes/presentation/note_detail/note_detail_screen.dart';
import 'package:adhdnotes/presentation/providers/notes_provider.dart';
import 'package:adhdnotes/presentation/providers/permissions_provider.dart';
import 'package:adhdnotes/presentation/providers/recording_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recording = context.watch<RecordingProvider>();
    final notesProvider = context.watch<NotesProvider>();
    final permissions = context.watch<PermissionsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('ADHD Notes')),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 24),
                Center(
                  child: _RecordButton(
                    enabled: !permissions.isLoading && permissions.microphoneGranted,
                    isRecording: recording.isRecording,
                    onPressed: recording.toggleRecording,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TranscriptCard(
                    text: recording.liveTranscript,
                    error: recording.lastError,
                    permissionsLoading: permissions.isLoading,
                    microphoneGranted: permissions.microphoneGranted,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _NotesList(notesProvider: notesProvider),
                ),
              ],
            ),
            if (recording.isProcessing)
              const ColoredBox(
                color: Color(0x88000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({
    required this.enabled,
    required this.isRecording,
    required this.onPressed,
  });

  final bool enabled;
  final bool isRecording;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = isRecording ? Colors.red : Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: 140,
      height: 140,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        child: Icon(isRecording ? Icons.stop : Icons.mic, size: 54),
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({
    required this.text,
    required this.error,
    required this.permissionsLoading,
    required this.microphoneGranted,
  });

  final String text;
  final String? error;
  final bool permissionsLoading;
  final bool microphoneGranted;

  @override
  Widget build(BuildContext context) {
    final message = permissionsLoading
        ? 'Requesting permissions…'
        : (!microphoneGranted ? 'Microphone permission denied. Enable it in Settings to record.' : null);

    if (text.trim().isEmpty && error == null && message == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null)
            Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
          if (text.trim().isNotEmpty) Text(text),
        ],
      ),
    );
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList({required this.notesProvider});

  final NotesProvider notesProvider;

  @override
  Widget build(BuildContext context) {
    if (notesProvider.isLoading && notesProvider.notes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notesProvider.error != null && notesProvider.notes.isEmpty) {
      return Center(child: Text(notesProvider.error!));
    }

    final notes = notesProvider.notes;
    if (notes.isEmpty) {
      return const Center(child: Text('No notes yet. Tap record to start.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: notes.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final note = notes[index];
        final subtitleParts = <String>[];
        subtitleParts.add(MaterialLocalizations.of(context).formatMediumDate(note.createdAt));
        if (note.eventDate != null) {
          subtitleParts.add('Event');
        }

        return ListTile(
          title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(subtitleParts.join(' • ')),
          trailing: note.eventDate == null ? null : const Icon(Icons.event),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
            );
          },
        );
      },
    );
  }
}
