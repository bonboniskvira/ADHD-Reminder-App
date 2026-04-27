import 'package:adhdnotes/services/notifications/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionsState {
  const PermissionsState({
    required this.microphoneGranted,
    required this.calendarGranted,
    required this.notificationsGranted,
  });

  final bool microphoneGranted;
  final bool calendarGranted;
  final bool notificationsGranted;
}

class PermissionsService {
  PermissionsService({required NotificationService notificationService})
      : _notificationService = notificationService;

  static const _requestedKey = 'permissions_requested_v1';

  final NotificationService _notificationService;

  Future<PermissionsState> ensureRequestedOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyRequested = prefs.getBool(_requestedKey) ?? false;
    if (alreadyRequested) {
      return PermissionsState(
        microphoneGranted: await Permission.microphone.isGranted,
        calendarGranted: await _isCalendarGranted(),
        notificationsGranted: await Permission.notification.isGranted,
      );
    }

    final micStatus = await Permission.microphone.request();
    final calendarGranted = await _requestCalendar();

    await _notificationService.requestPermissions();
    final notifStatus = await Permission.notification.request();

    await prefs.setBool(_requestedKey, true);

    return PermissionsState(
      microphoneGranted: micStatus.isGranted,
      calendarGranted: calendarGranted,
      notificationsGranted: notifStatus.isGranted,
    );
  }

  Future<bool> _isCalendarGranted() async {
    final full = await Permission.calendarFullAccess.status;
    if (full.isGranted) return true;
    final writeOnly = await Permission.calendarWriteOnly.status;
    return writeOnly.isGranted;
  }

  Future<bool> _requestCalendar() async {
    final full = await Permission.calendarFullAccess.request();
    if (full.isGranted) return true;
    final writeOnly = await Permission.calendarWriteOnly.request();
    return writeOnly.isGranted;
  }
}
