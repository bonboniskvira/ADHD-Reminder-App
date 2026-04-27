# Flutter iOS ADHD Notes App — Implementation Plan

## Summary

Build a Flutter (iOS-targeted) app that lets ADHD users tap a large record button to transcribe speech in real time, send the transcript to DeepSeek for JSON-formatted note cleanup + event extraction, persist notes locally (Sqflite), and (when an event date/time is detected) create a calendar event and schedule a local notification 5 hours before.

## Current State Analysis

- Repository contains only [LICENSE](file:///workspace/LICENSE).
- No existing Flutter project structure, dependencies, or iOS configuration present.

## Assumptions & Decisions (Locked)

- **Project**: Create Flutter app named `adhdnotes` with iOS bundle identifier `com.kner.adhdnotes` (via `flutter create --org com.kner adhdnotes`).
- **DeepSeek endpoint**: Use `https://api.deepseek.com/v1/chat/completions` (without the trailing `)` from the prompt).
- **DeepSeek model**: `deepseek-chat`.
- **DeepSeek response JSON fields**: exactly `note`, `event_title`, `event_date` (no extra fields). Home list title is derived locally.
- **Title derivation**: `event_title` if present, else first non-empty line of formatted note (markdown), else a shortened snippet.
- **Event parsing**:
  - `event_date` is expected to be an ISO 8601 date-time string or `null`.
  - If DeepSeek returns a date-only ISO string (rare but possible), normalize to local time at `09:00`.
- **Calendar event details**: default duration 60 minutes; notes store event metadata (since `add_2_calendar` does not provide a stable event identifier on iOS).
- **Notification scheduling**: schedule at `eventDateTime - 5 hours`; if that is in the past, skip scheduling.
- **State management**: `provider` only (no Riverpod/BLoC).
- **Architecture**: “clean-ish” layering with `services/` for external integrations and `data/` for persistence, `presentation/` for UI/state.

## Proposed Changes

### 1) Create Flutter project + iOS targeting

- Create a new Flutter project at `/workspace/adhdnotes/`.
- Ensure iOS tooling is enabled (generated `ios/` folder).
- Set iOS display name to “ADHD Notes” in `ios/Runner/Info.plist` (bundle id stays `com.kner.adhdnotes`).

**Files/dirs created by Flutter tooling**
- `adhdnotes/pubspec.yaml`
- `adhdnotes/lib/**`
- `adhdnotes/ios/**`

### 2) Dependencies and configuration

Update [pubspec.yaml](file:///workspace/adhdnotes/pubspec.yaml) with null-safe, Flutter-stable compatible packages:

- `provider`
- `speech_to_text`
- `http`
- `flutter_dotenv`
- `sqflite`
- `path_provider`
- `add_2_calendar`
- `flutter_local_notifications`
- `timezone`
- `flutter_timezone`
- `permission_handler`
- `shared_preferences`

Environment variable setup:

- Add `adhdnotes/.env` (not committed) containing `DEEPSEEK_API_KEY=...`.
- Add `.env` to `adhdnotes/.gitignore`.
- Load `.env` via `flutter_dotenv` in `main.dart`.

### 3) iOS permissions + entitlements

Update [Info.plist](file:///workspace/adhdnotes/ios/Runner/Info.plist) with usage descriptions:

- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`
- `NSCalendarsUsageDescription`
- (Optional but commonly needed) `NSUserNotificationsUsageDescription`

Implement a first-launch permission request flow:

- On first app start (tracked via `shared_preferences`), request:
  - Microphone
  - Calendar
  - Notifications
- If denied, keep app functional where possible (record button disabled if mic denied; calendar/notifications skipped if denied).

### 4) Data layer (Sqflite)

Create:

- [note.dart](file:///workspace/adhdnotes/lib/data/models/note.dart): note model + mapping helpers.
- [app_database.dart](file:///workspace/adhdnotes/lib/data/db/app_database.dart): open DB and create schema.
- [notes_repository.dart](file:///workspace/adhdnotes/lib/data/repositories/notes_repository.dart): CRUD API.

Schema (single table `notes`):

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `title TEXT NOT NULL`
- `raw_transcript TEXT NOT NULL`
- `formatted_note_md TEXT NOT NULL`
- `created_at TEXT NOT NULL` (ISO 8601)
- `event_title TEXT NULL`
- `event_date TEXT NULL` (ISO 8601)
- `event_created INTEGER NOT NULL` (0/1)

### 5) Services layer

Create `lib/services/` with focused services:

- [deepseek_client.dart](file:///workspace/adhdnotes/lib/services/api/deepseek_client.dart)
  - Uses `http` with `Authorization: Bearer <key>`.
  - Sends `system` + `user` messages to DeepSeek.
  - Parses `choices[0].message.content` as JSON into a typed result.
  - Rejects/handles invalid JSON safely.

- [deepseek_prompts.dart](file:///workspace/adhdnotes/lib/services/api/deepseek_prompts.dart)
  - Holds the system prompt string (single source of truth).
  - Prompt requirements:
    - Respond with strict JSON only.
    - Keys: `note`, `event_title`, `event_date`.
    - `event_date` must be ISO 8601 date-time or `null`.

- [speech_service.dart](file:///workspace/adhdnotes/lib/services/speech/speech_service.dart)
  - Wraps `speech_to_text` init/start/stop.
  - Exposes a stream/callback for partial transcription updates.

- [calendar_service.dart](file:///workspace/adhdnotes/lib/services/calendar/calendar_service.dart)
  - Creates an `Event` and calls `Add2Calendar.addEvent2Cal`.
  - Returns whether the add attempt succeeded.

- [notification_service.dart](file:///workspace/adhdnotes/lib/services/notifications/notification_service.dart)
  - Initializes `flutter_local_notifications`.
  - Configures timezone and schedules a notification for a given DateTime.

- [permissions_service.dart](file:///workspace/adhdnotes/lib/services/permissions/permissions_service.dart)
  - Requests mic/calendar/notification permissions.
  - Provides “canRecord”, “canCalendar”, “canNotify” flags for UI decisions.

### 6) Provider state (simple + explicit)

Create:

- [notes_provider.dart](file:///workspace/adhdnotes/lib/presentation/providers/notes_provider.dart)
  - Loads recent notes, listens for inserts/deletes, exposes `List<Note>`.

- [recording_provider.dart](file:///workspace/adhdnotes/lib/presentation/providers/recording_provider.dart)
  - Drives the core flow state machine:
    - idle → recording (partial transcript updates) → processing (DeepSeek) → saved/error
  - Owns:
    - `isRecording`, `isProcessing`
    - `liveTranscript`
    - `lastError`
  - On stop:
    - calls DeepSeek → derives title → saves to DB
    - if event detected: add to calendar → schedule notification
    - refreshes notes list

### 7) UI screens

Create two screens under `lib/presentation/`:

- [home_screen.dart](file:///workspace/adhdnotes/lib/presentation/home/home_screen.dart)
  - Big prominent record button centered.
  - Real-time transcript preview while recording.
  - List of recent notes below (title + created date + optional event indicator).
  - Tap note to open detail.

- [note_detail_screen.dart](file:///workspace/adhdnotes/lib/presentation/note_detail/note_detail_screen.dart)
  - Shows formatted markdown note (rendered via a markdown widget).
  - Shows extracted event info (title/date) if present.
  - Delete action:
    - Deletes note from DB.
    - (Out of scope) Removing calendar event from iOS calendar (no event id).

Navigation:

- Use `Navigator.push` with Material routes (simple).

### 8) Verification steps (executor checklist)

Local checks to run after implementation:

- `flutter --version` (confirm latest stable)
- `cd adhdnotes && flutter pub get`
- `cd adhdnotes && flutter analyze`
- `cd adhdnotes && flutter test`
- iOS build sanity:
  - `cd adhdnotes && flutter build ios --no-codesign`

Runtime acceptance checks (manual):

- First launch prompts for microphone/calendar/notifications.
- Record button:
  - Shows partial transcription in real time.
  - Stop triggers DeepSeek formatting.
- Note appears in recent list and persists across app restarts.
- If an `event_date` is present:
  - Calendar add prompt/flow completes.
  - Notification is scheduled 5 hours before (or skipped if in past).
- Note detail renders formatted markdown and allows deletion.

