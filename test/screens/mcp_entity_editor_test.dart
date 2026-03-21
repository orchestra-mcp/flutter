import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/screens/library/mcp_entity_editor.dart';
import 'package:orchestra/widgets/markdown_editor.dart';

/// Tests for McpEntityEditorScreen.
///
/// Full widget pumping is skipped because McpEntityEditorScreen depends on
/// Riverpod providers, ThemeTokens, GoRouter, and MCP API. These tests verify
/// constructor behavior and that MarkdownEditor integration compiles correctly.
void main() {
  group('McpEntityEditorScreen', () {
    test('const-constructible for new agent', () {
      const screen = McpEntityEditorScreen(entityType: McpEntityType.agent);
      expect(screen, isA<McpEntityEditorScreen>());
      expect(screen.entityType, McpEntityType.agent);
      expect(screen.entityId, isNull);
      expect(screen.isNew, isTrue);
    });

    test('accepts entityId for editing existing entity', () {
      const screen = McpEntityEditorScreen(
        entityType: McpEntityType.doc,
        entityId: 'DOC-123',
      );
      expect(screen.entityId, 'DOC-123');
      expect(screen.isNew, isFalse);
    });

    test('is a ConsumerStatefulWidget', () {
      const screen = McpEntityEditorScreen(entityType: McpEntityType.skill);
      expect(screen, isA<ConsumerStatefulWidget>());
    });

    test('all entity types are constructible', () {
      for (final type in McpEntityType.values) {
        final screen = McpEntityEditorScreen(entityType: type);
        expect(screen.entityType, type);
        expect(screen.isNew, isTrue);
      }
    });

    test('accepts projectId and initialData', () {
      const screen = McpEntityEditorScreen(
        entityType: McpEntityType.feature,
        projectId: 'orchestra-agents',
        initialData: {'title': 'Test Feature'},
      );
      expect(screen.projectId, 'orchestra-agents');
      expect(screen.initialData, {'title': 'Test Feature'});
    });

    test('MarkdownEditor accepts controller for entity body integration', () {
      final controller = TextEditingController(text: '# Agent Prompt');
      final editor = MarkdownEditor(
        controller: controller,
        hintText: 'System prompt...',
      );
      expect(editor.controller, same(controller));
      expect(editor.hintText, 'System prompt...');
      controller.dispose();
    });
  });
}
