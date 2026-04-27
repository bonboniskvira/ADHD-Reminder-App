import 'package:adhdnotes/core/utils/note_utils.dart';
import 'package:adhdnotes/data/models/note.dart';
import 'package:adhdnotes/data/repositories/notes_repository.dart';
import 'package:adhdnotes/services/api/deepseek_client.dart';
import 'package:adhdnotes/services/calendar/calendar_service.dart';
import 'package:adhdnotes/services/notifications/notification_service.dart';
import 'package:adhdnotes/services/speech/speech_service.dart';
import 'package:flutter/foundation.dart';

import 'package:adhdnotes/presentation/providers/notes_provider.dart';
import 'package:adhdnotes/presentation/providers/permissions_provider.dart';

class RecordingProvider extends ChangeNotifier {
  RecordingProvider({
    required SpeechService speechService,
    required DeepSeekClient deepSeekClient,
    required NotesRepository notesRepository,
    required CalendarService calendarService,
    required NotificationService notificationService,
    required PermissionsProvider permissionsProvider,
  })  : _speechService = speechService,
        _deepSeekClient = deepSeekClient,
        _notesRepository = notesRepository,
        _calendarService = calendarService,
        _notificationService = notificationService,
        _permissionsProvider = permissionsProvider;

  final SpeechService _speechService;
  final DeepSeekClient _deepSeekClient;
  final NotesRepository _notesRepository;
  final CalendarService _calendarService;
  final NotificationService _notificationService;
  final PermissionsProvider _permissionsProvider;

  NotesProvider? _notesProvider;

  bool _isRecording = false;
  bool _isProcessing = false;
  String _liveTranscript = '';
  String? _lastError;

  bool get isRecording => _isRecording;
  bool get isProcessing => _isProcessing;
  String get liveTranscript => _liveTranscript;
  String? get lastError => _lastError;

  set notesProvider(NotesProvider? value) {
    _notesProvider = value;
  }

  Future<void> toggleRecording() async {
    _lastError = null;
    notifyListeners();

    if (_isProcessing) return;

    if (_isRecording) {
      await _stopAndProcess();
      return;
    }

    await _startRecording();
  }

  Future<void> _startRecording() async {
    await _permissionsProvider.initialize();
    if (!_permissionsProvider.microphoneGranted) {
      _lastError = 'Microphone permission is required to record.';
      notifyListeners();
      return;
    }

    _liveTranscript = '';
    _isRecording = true;
    notifyListeners();

    try {
      await _speechService.startListening(
        onResult: (words, isFinal) {
          _liveTranscript = words;
          notifyListeners();
        },
      );
    } catch (e) {
      _isRecording = false;
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> _stopAndProcess() async {
    _isRecording = false;
    notifyListeners();

    await _speechService.stopListening();

    final transcript = _liveTranscript.trim();
    if (transcript.isEmpty) return;

    _isProcessing = true;
    notifyListeners();

    try {
      final formatted = await _deepSeekClient.formatTranscript(transcript);
      final title = deriveNoteTitle(
        formattedMarkdown: formatted.noteMarkdown,
        eventTitle: formatted.eventTitle,
      );

      final eventDate = formatted.eventDate;
      final eventTitle = formatted.eventTitle ?? title;

      var eventCreated = false;
      if (eventDate != null && _permissionsProvider.calendarGranted) {
        eventCreated = await _calendarService.createEvent(
          title: eventTitle,
          start: eventDate,
          duration: const Duration(hours: 1),
          description: formatted.noteMarkdown,
        );
      }

      final note = Note(
        id: null,
        title: title,
        rawTranscript: transcript,
        formattedNoteMarkdown: formatted.noteMarkdown,
        createdAt: DateTime.now(),
        eventTitle: eventDate == null ? null : eventTitle,
        eventDate: eventDate,
        eventCreated: eventCreated,
      );

      final id = await _notesRepository.insert(note);

      if (eventDate != null && _permissionsProvider.notificationsGranted) {
        await _notificationService.scheduleEventReminder(
          id: id,
          title: eventTitle,
          eventDateTime: eventDate,
        );
      }

      await _notesProvider?.load();
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}

