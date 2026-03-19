import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/platform/stub/health_stub.dart';
import 'package:orchestra/platform/stub/local_auth_stub.dart';
import 'package:orchestra/platform/stub/tray_stub.dart';

void main() {
  group('TrayManagerService stub', () {
    test('init, showMenu, hide complete without throwing', () async {
      final svc = TrayManagerService();
      await expectLater(svc.init(), completes);
      await expectLater(svc.showMenu(), completes);
      await expectLater(svc.hide(), completes);
    });
  });

  group('HealthStub', () {
    test('all methods return false/null without throwing', () async {
      final stub = HealthStub();
      expect(await stub.isAvailable(), isFalse);
      expect(await stub.getSteps(), isNull);
      expect(await stub.getHeartRate(), isNull);
    });
  });

  group('LocalAuthStub', () {
    test('authenticate and isAvailable both return false', () async {
      final stub = LocalAuthStub();
      expect(await stub.authenticate(), isFalse);
      expect(await stub.isAvailable(), isFalse);
    });
  });
}
