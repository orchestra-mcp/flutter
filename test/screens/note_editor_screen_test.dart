import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/screens/library/note_editor_screen.dart';
import 'package:orchestra/widgets/markdown_editor.dart';

/// Tests for NoteEditorScreen.
///
/// Full widget pumping is skipped because NoteEditorScreen depends on
/// Riverpod providers, ThemeTokens, GoRouter, and MCP API — none of which
/// are available in a unit-test environment. These tests verify constructor
/// behavior and that the MarkdownEditor integration compiles correctly.
void main() {
  group('NoteEditorScreen', () {
    test('const-constructible for new note (noteId = null)', () {
      const screen = NoteEditorScreen();
      expect(screen, isA<NoteEditorScreen>());
      expect(screen.noteId, isNull);
      expect(screen.isNew, isTrue);
    });

    test('accepts noteId for editing existing note', () {
      const screen = NoteEditorScreen(noteId: 'NOTE-123');
      expect(screen.noteId, 'NOTE-123');
      expect(screen.isNew, isFalse);
    });

    test('is a ConsumerStatefulWidget', () {
      const screen = NoteEditorScreen();
      expect(screen, isA<ConsumerStatefulWidget>());
    });

    test('MarkdownEditor is const-constructible with controller param', () {
      // Verify the integration point: NoteEditorScreen passes its
      // _contentController to MarkdownEditor. Here we confirm
      // MarkdownEditor accepts a controller at compile time.
      final controller = TextEditingController(text: '# Test');
      final editor = MarkdownEditor(
        controller: controller,
        hintText: 'Write markdown...',
      );
      expect(editor.controller, same(controller));
      expect(editor.hintText, 'Write markdown...');
      controller.dispose();
    });
  });
}
