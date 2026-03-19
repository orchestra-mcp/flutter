import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/terminal/terminal_session_model.dart';
import 'package:orchestra/features/terminal/terminal_sessions_provider.dart';

void main() {
  // ── TerminalSessionType ─────────────────────────────────────────────────────

  group('TerminalSessionType', () {
    test('has three values: terminal, ssh, claude', () {
      expect(TerminalSessionType.values.length, 3);
      expect(
        TerminalSessionType.values,
        containsAll([
          TerminalSessionType.terminal,
          TerminalSessionType.ssh,
          TerminalSessionType.claude,
        ]),
      );
    });
  });

  // ── TerminalSessionStatus ───────────────────────────────────────────────────

  group('TerminalSessionStatus', () {
    test('has four values: connecting, connected, disconnected, error', () {
      expect(TerminalSessionStatus.values.length, 4);
      expect(
        TerminalSessionStatus.values,
        containsAll([
          TerminalSessionStatus.connecting,
          TerminalSessionStatus.connected,
          TerminalSessionStatus.disconnected,
          TerminalSessionStatus.error,
        ]),
      );
    });
  });

  // ── TerminalSessionModel ────────────────────────────────────────────────────

  group('TerminalSessionModel', () {
    final createdAt = DateTime(2026, 3, 16, 10, 0);

    TerminalSessionModel makeSession({
      String id = 'term-1',
      TerminalSessionType type = TerminalSessionType.terminal,
      TerminalSessionStatus status = TerminalSessionStatus.connecting,
      String label = 'Terminal',
    }) {
      return TerminalSessionModel(
        id: id,
        type: type,
        status: status,
        label: label,
        createdAt: createdAt,
      );
    }

    // -- Construction ----------------------------------------------------------

    test('constructs with required fields', () {
      final session = makeSession();
      expect(session.id, 'term-1');
      expect(session.type, TerminalSessionType.terminal);
      expect(session.status, TerminalSessionStatus.connecting);
      expect(session.label, 'Terminal');
      expect(session.createdAt, createdAt);
    });

    test('optional SSH fields default to null', () {
      final session = makeSession();
      expect(session.sshHost, isNull);
      expect(session.sshUser, isNull);
      expect(session.sshPort, isNull);
      expect(session.sshPassword, isNull);
      expect(session.sshKeyFile, isNull);
    });

    test('optional Claude fields default to null', () {
      final session = makeSession();
      expect(session.claudeModel, isNull);
      expect(session.claudeSessionId, isNull);
    });

    test('constructs SSH session with all SSH fields', () {
      final session = TerminalSessionModel(
        id: 'ssh-1',
        type: TerminalSessionType.ssh,
        status: TerminalSessionStatus.connected,
        label: 'admin@example.com',
        createdAt: createdAt,
        sshHost: 'example.com',
        sshUser: 'admin',
        sshPort: 2222,
        sshPassword: 'secret123',
        sshKeyFile: '/home/admin/.ssh/id_rsa',
      );
      expect(session.sshHost, 'example.com');
      expect(session.sshUser, 'admin');
      expect(session.sshPort, 2222);
      expect(session.sshPassword, 'secret123');
      expect(session.sshKeyFile, '/home/admin/.ssh/id_rsa');
    });

    test('constructs Claude session with Claude fields', () {
      final session = TerminalSessionModel(
        id: 'claude-1',
        type: TerminalSessionType.claude,
        status: TerminalSessionStatus.connected,
        label: 'Claude (claude-sonnet-4-6)',
        createdAt: createdAt,
        claudeModel: 'claude-sonnet-4-6',
        claudeSessionId: 'sess-xyz',
      );
      expect(session.claudeModel, 'claude-sonnet-4-6');
      expect(session.claudeSessionId, 'sess-xyz');
    });

    // -- Equality (id-only) ----------------------------------------------------

    test('two instances with the same id are equal', () {
      final a = makeSession(id: 'term-42');
      final b = TerminalSessionModel(
        id: 'term-42',
        type: TerminalSessionType.ssh, // different type
        status: TerminalSessionStatus.error, // different status
        label: 'Something else', // different label
        createdAt: DateTime(2025, 1, 1), // different date
      );
      expect(a, equals(b));
    });

    test('two instances with different ids are not equal', () {
      final a = makeSession(id: 'term-1');
      final b = makeSession(id: 'term-2');
      expect(a, isNot(equals(b)));
    });

    test('hashCode is based on id', () {
      final a = makeSession(id: 'term-7');
      final b = TerminalSessionModel(
        id: 'term-7',
        type: TerminalSessionType.claude,
        status: TerminalSessionStatus.disconnected,
        label: 'x',
        createdAt: DateTime.now(),
      );
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode equals id.hashCode directly', () {
      final session = makeSession(id: 'term-99');
      expect(session.hashCode, 'term-99'.hashCode);
    });

    test('identical instance equals itself', () {
      final session = makeSession();
      // ignore: unrelated_type_equality_checks
      expect(session == session, isTrue);
    });

    test('does not equal a non-TerminalSessionModel object', () {
      final session = makeSession();
      // ignore: unrelated_type_equality_checks
      expect(session == 'term-1', isFalse);
    });

    // -- copyWith --------------------------------------------------------------

    test('copyWith returns new instance with updated status', () {
      final original = makeSession(status: TerminalSessionStatus.connecting);
      final updated = original.copyWith(
        status: TerminalSessionStatus.connected,
      );
      expect(updated.status, TerminalSessionStatus.connected);
      expect(updated.id, original.id);
      expect(updated.type, original.type);
      expect(updated.label, original.label);
      expect(updated.createdAt, original.createdAt);
    });

    test('copyWith returns new instance with updated label', () {
      final original = makeSession(label: 'bash');
      final updated = original.copyWith(label: 'zsh');
      expect(updated.label, 'zsh');
      expect(updated.id, original.id);
    });

    test('copyWith preserves original when no arguments supplied', () {
      final original = makeSession(
        status: TerminalSessionStatus.connected,
        label: 'Terminal',
      );
      final copy = original.copyWith();
      expect(copy.status, TerminalSessionStatus.connected);
      expect(copy.label, 'Terminal');
      expect(copy.id, original.id);
    });

    test('copyWith preserves SSH fields on status update', () {
      final original = TerminalSessionModel(
        id: 'ssh-1',
        type: TerminalSessionType.ssh,
        status: TerminalSessionStatus.connecting,
        label: 'user@host',
        createdAt: createdAt,
        sshHost: 'host',
        sshUser: 'user',
        sshPort: 22,
        sshPassword: 'pass',
        sshKeyFile: '/path/to/key',
      );
      final updated = original.copyWith(
        status: TerminalSessionStatus.connected,
      );
      expect(updated.status, TerminalSessionStatus.connected);
      expect(updated.sshHost, 'host');
      expect(updated.sshUser, 'user');
      expect(updated.sshPort, 22);
      expect(updated.sshPassword, 'pass');
      expect(updated.sshKeyFile, '/path/to/key');
    });

    test('copyWith updates claudeSessionId', () {
      final original = TerminalSessionModel(
        id: 'claude-1',
        type: TerminalSessionType.claude,
        status: TerminalSessionStatus.connecting,
        label: 'Claude (claude-sonnet-4-6)',
        createdAt: createdAt,
        claudeModel: 'claude-sonnet-4-6',
      );
      final updated = original.copyWith(claudeSessionId: 'sess-claude-abc');
      expect(updated.claudeSessionId, 'sess-claude-abc');
      expect(updated.claudeModel, 'claude-sonnet-4-6'); // preserved
    });

    test('copyWith result is equal to original (same id)', () {
      final original = makeSession();
      final copy = original.copyWith(status: TerminalSessionStatus.error);
      expect(copy, equals(original)); // equality is id-only
    });

    test('copyWith can update multiple fields at once', () {
      final original = makeSession(
        status: TerminalSessionStatus.connecting,
        label: 'Terminal',
      );
      final updated = original.copyWith(
        status: TerminalSessionStatus.connected,
        label: 'zsh',
      );
      expect(updated.status, TerminalSessionStatus.connected);
      expect(updated.label, 'zsh');
      expect(updated.id, original.id);
      expect(updated.type, original.type);
      expect(updated.createdAt, original.createdAt);
    });

    // -- toString --------------------------------------------------------------

    test('toString includes id, type, status, and label', () {
      final session = makeSession(
        id: 'term-1',
        type: TerminalSessionType.terminal,
        status: TerminalSessionStatus.connecting,
        label: 'Terminal',
      );
      final str = session.toString();
      expect(str, contains('term-1'));
      expect(str, contains('TerminalSessionType.terminal'));
      expect(str, contains('TerminalSessionStatus.connecting'));
      expect(str, contains('Terminal'));
    });

    test('toString for SSH session contains ssh type', () {
      final session = makeSession(
        id: 'ssh-2',
        type: TerminalSessionType.ssh,
        label: 'user@host',
      );
      final str = session.toString();
      expect(str, contains('ssh-2'));
      expect(str, contains('TerminalSessionType.ssh'));
      expect(str, contains('user@host'));
    });

    test('toString for Claude session contains claude type', () {
      final session = makeSession(
        id: 'claude-3',
        type: TerminalSessionType.claude,
        status: TerminalSessionStatus.connected,
        label: 'Claude',
      );
      final str = session.toString();
      expect(str, contains('claude-3'));
      expect(str, contains('TerminalSessionType.claude'));
      expect(str, contains('TerminalSessionStatus.connected'));
    });
  });

  // ── terminalSessionsProvider ────────────────────────────────────────────────

  group('TerminalSessionsNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('initial state is an empty list', () {
      final sessions = container.read(terminalSessionsProvider);
      expect(sessions, isEmpty);
    });

    test('initial state is a List<TerminalSessionModel>', () {
      final sessions = container.read(terminalSessionsProvider);
      expect(sessions, isA<List<TerminalSessionModel>>());
    });

    test('independent containers have isolated state', () {
      final containerA = ProviderContainer();
      final containerB = ProviderContainer();
      addTearDown(containerA.dispose);
      addTearDown(containerB.dispose);

      expect(containerA.read(terminalSessionsProvider), isEmpty);
      expect(containerB.read(terminalSessionsProvider), isEmpty);
      expect(
        identical(
          containerA.read(terminalSessionsProvider),
          containerB.read(terminalSessionsProvider),
        ),
        isFalse,
      );
    });
  });

  // ── activeTerminalIdProvider ────────────────────────────────────────────────

  group('ActiveTerminalId', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('initial state is null', () {
      expect(container.read(activeTerminalIdProvider), isNull);
    });

    test('set updates the active id', () {
      container.read(activeTerminalIdProvider.notifier).set('term-1');
      expect(container.read(activeTerminalIdProvider), 'term-1');
    });

    test('set to null clears the active id', () {
      container.read(activeTerminalIdProvider.notifier).set('term-1');
      container.read(activeTerminalIdProvider.notifier).set(null);
      expect(container.read(activeTerminalIdProvider), isNull);
    });

    test('set overwrites a previous value', () {
      container.read(activeTerminalIdProvider.notifier).set('term-1');
      container.read(activeTerminalIdProvider.notifier).set('ssh-2');
      expect(container.read(activeTerminalIdProvider), 'ssh-2');
    });

    test('independent containers have isolated active id state', () {
      final containerA = ProviderContainer();
      final containerB = ProviderContainer();
      addTearDown(containerA.dispose);
      addTearDown(containerB.dispose);

      containerA.read(activeTerminalIdProvider.notifier).set('term-42');
      expect(containerA.read(activeTerminalIdProvider), 'term-42');
      expect(containerB.read(activeTerminalIdProvider), isNull);
    });
  });
}
