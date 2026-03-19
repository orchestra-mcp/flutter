import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/desktop/tray_manager_service.dart';

void main() {
  group('TrayManagerService', () {
    test('singleton is same instance', () {
      expect(TrayManagerService.instance, same(TrayManagerService.instance));
    });

    test('initial state is stopped', () {
      expect(TrayManagerService.instance.state, TrayIconState.stopped);
    });

    test('updateIcon changes state', () async {
      await TrayManagerService.instance.updateIcon(TrayIconState.running);
      expect(TrayManagerService.instance.state, TrayIconState.running);
      // reset
      await TrayManagerService.instance.updateIcon(TrayIconState.stopped);
    });
  });
}
