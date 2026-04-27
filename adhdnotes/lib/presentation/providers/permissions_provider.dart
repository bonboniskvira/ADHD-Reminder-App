import 'package:adhdnotes/services/permissions/permissions_service.dart';
import 'package:flutter/foundation.dart';

class PermissionsProvider extends ChangeNotifier {
  PermissionsProvider({required PermissionsService permissionsService})
      : _permissionsService = permissionsService;

  final PermissionsService _permissionsService;

  bool _isLoading = false;
  PermissionsState? _state;

  bool get isLoading => _isLoading;
  PermissionsState? get state => _state;

  bool get microphoneGranted => _state?.microphoneGranted ?? false;
  bool get calendarGranted => _state?.calendarGranted ?? false;
  bool get notificationsGranted => _state?.notificationsGranted ?? false;

  Future<void> initialize() async {
    if (_isLoading || _state != null) return;
    _isLoading = true;
    notifyListeners();

    try {
      _state = await _permissionsService.ensureRequestedOnFirstLaunch();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

