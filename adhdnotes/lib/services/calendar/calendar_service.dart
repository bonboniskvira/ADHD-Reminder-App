import 'package:add_2_calendar/add_2_calendar.dart';

class CalendarService {
  Future<bool> createEvent({
    required String title,
    required DateTime start,
    required Duration duration,
    String? description,
  }) async {
    final event = Event(
      title: title,
      description: description,
      startDate: start,
      endDate: start.add(duration),
    );

    return Add2Calendar.addEvent2Cal(event);
  }
}

