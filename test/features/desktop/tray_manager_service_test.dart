import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/desktop/tray_manager_service.dart';

void main() {
  group('TrayIconState', () {
    test('enum has four values', () {
      expect(TrayIconState.values.length, 4);
      expect(
        TrayIconState.values,
        containsAll([
          TrayIconState.running,
          TrayIconState.starting,
          TrayIconState.stopped,
          TrayIconState.error,
        ]),
      );
    });
  });

  group('TrayManagerService', () {
    test('instance is a singleton', () {
      expect(
        identical(TrayManagerService.instance, TrayManagerService.instance),
        isTrue,
      );
    });

    test('initial state is stopped', () {
      expect(TrayManagerService.instance.state, TrayIconState.stopped);
    });

    test('updateIcon changes the state', () async {
      final svc = TrayManagerService.instance;
      await svc.updateIcon(TrayIconState.running);
      expect(svc.state, TrayIconState.running);
      // restore
      await svc.updateIcon(TrayIconState.stopped);
    });

    test('init and dispose complete without error', () async {
      final svc = TrayManagerService.instance;
      await expectLater(svc.init(), completes);
      await expectLater(svc.dispose(), completes);
    });

    test('buildMenu completes without error', () async {
      final svc = TrayManagerService.instance;
      await expectLater(
        svc.buildMenu(
          workspaceNames: ['default', 'work'],
          activeWorkspaceId: 'ws-1',
          onShowHide: () {},
          onQuit: () {},
        ),
        completes,
      );
    });
  });
}
