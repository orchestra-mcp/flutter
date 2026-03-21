import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/widgets/markdown_editor.dart';

/// Tests for the MarkdownEditor widget.
///
/// Full widget pumping is skipped because MarkdownEditor depends on
/// [ThemeTokens] being in the widget tree. These tests verify constructor
/// behavior and external controller lifecycle.
void main() {
  group('MarkdownEditor', () {
    test('const-constructible with defaults', () {
      const editor = MarkdownEditor();
      expect(editor, isA<MarkdownEditor>());
      expect(editor.initialText, '');
      expect(editor.controller, isNull);
      expect(editor.hintText, 'Start writing markdown...');
    });

    test('accepts external controller', () {
      final controller = TextEditingController(text: '# Hello');
      final editor = MarkdownEditor(controller: controller);
      expect(editor.controller, same(controller));
      controller.dispose();
    });

    test('initialText is set when no controller', () {
      const editor = MarkdownEditor(initialText: '**bold**');
      expect(editor.initialText, '**bold**');
      expect(editor.controller, isNull);
    });

    test('custom hintText', () {
      const editor = MarkdownEditor(hintText: 'Write here...');
      expect(editor.hintText, 'Write here...');
    });

    test('autoSaveDelay defaults to 500ms', () {
      const editor = MarkdownEditor();
      expect(editor.autoSaveDelay, const Duration(milliseconds: 500));
    });

    test('onChanged callback is stored', () {
      void callback(String s) {}
      final editor = MarkdownEditor(onChanged: callback);
      expect(editor.onChanged, same(callback));
    });
  });
}
