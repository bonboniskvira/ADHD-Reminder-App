import 'dart:convert';

import 'package:adhdnotes/core/utils/note_utils.dart';
import 'package:adhdnotes/services/api/deepseek_models.dart';
import 'package:adhdnotes/services/api/deepseek_prompts.dart';
import 'package:http/http.dart' as http;

class DeepSeekClient {
  DeepSeekClient({
    required String apiKey,
    http.Client? httpClient,
    this.baseUrl = 'https://api.deepseek.com/v1/chat/completions',
    this.model = 'deepseek-chat',
  })  : _apiKey = apiKey,
        _httpClient = httpClient ?? http.Client();

  final String _apiKey;
  final http.Client _httpClient;
  final String baseUrl;
  final String model;

  Future<DeepSeekNoteFormatResult> formatTranscript(String transcript) async {
    final uri = Uri.parse(baseUrl);

    final payload = <String, Object?>{
      'model': model,
      'temperature': 0.2,
      'messages': [
        {'role': 'system', 'content': deepSeekSystemPrompt},
        {'role': 'user', 'content': transcript},
      ],
    };

    final response = await _httpClient.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DeepSeekException('DeepSeek request failed (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) {
      throw DeepSeekException('Unexpected DeepSeek response shape.');
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw DeepSeekException('DeepSeek returned no choices.');
    }

    final first = choices.first;
    if (first is! Map) throw DeepSeekException('Unexpected DeepSeek choice shape.');
    final message = first['message'];
    if (message is! Map) throw DeepSeekException('Unexpected DeepSeek message shape.');
    final content = message['content'];
    if (content is! String) throw DeepSeekException('DeepSeek message content was not a string.');

    final jsonText = stripCodeFences(content);
    final resultDecoded = jsonDecode(jsonText);
    if (resultDecoded is! Map<String, Object?>) {
      throw DeepSeekException('DeepSeek output was not a JSON object.');
    }

    final note = (resultDecoded['note'] as String?)?.trim() ?? '';
    final eventTitle = _nullableString(resultDecoded['event_title']);
    final eventDateRaw = _nullableString(resultDecoded['event_date']);

    final eventDate = eventDateRaw == null ? null : _parseIso8601Flexible(eventDateRaw);

    return DeepSeekNoteFormatResult(
      noteMarkdown: note,
      eventTitle: eventTitle,
      eventDate: eventDate,
    );
  }

  String? _nullableString(Object? v) {
    if (v == null) return null;
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }
    return null;
  }

  DateTime? _parseIso8601Flexible(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;

    try {
      if (!t.contains('T')) {
        final date = DateTime.parse(t);
        return DateTime(date.year, date.month, date.day, 9);
      }
      return DateTime.parse(t);
    } catch (_) {
      return null;
    }
  }
}

class DeepSeekException implements Exception {
  DeepSeekException(this.message);

  final String message;

  @override
  String toString() => 'DeepSeekException: $message';
}

