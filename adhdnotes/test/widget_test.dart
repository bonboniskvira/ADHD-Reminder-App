import 'package:flutter_test/flutter_test.dart';

import 'package:adhdnotes/core/utils/note_utils.dart';

void main() {
  test('deriveNoteTitle prefers event title', () {
    final title = deriveNoteTitle(formattedMarkdown: '- something', eventTitle: 'Meeting');
    expect(title, 'Meeting');
  });

  test('deriveNoteTitle derives from markdown', () {
    final title = deriveNoteTitle(formattedMarkdown: '# Todo\n- one', eventTitle: null);
    expect(title, 'Todo');
  });
}
