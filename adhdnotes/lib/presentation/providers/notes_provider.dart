import 'package:adhdnotes/data/models/note.dart';
import 'package:adhdnotes/data/repositories/notes_repository.dart';
import 'package:flutter/foundation.dart';

class NotesProvider extends ChangeNotifier {
  NotesProvider({required NotesRepository notesRepository}) : _notesRepository = notesRepository;

  final NotesRepository _notesRepository;

  List<Note> _notes = const [];
  bool _isLoading = false;
  String? _error;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await _notesRepository.getRecentNotes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteById(int id) async {
    await _notesRepository.delete(id);
    await load();
  }
}

