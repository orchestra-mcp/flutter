import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/installer/install_progress_model.dart';

void main() {
  group('InstallProgress', () {
    test('initial has stage checking and 0 percent', () {
      expect(InstallProgress.initial.stage, InstallStage.checking);
      expect(InstallProgress.initial.percent, 0);
      expect(InstallProgress.initial.error, isNull);
    });

    test('copyWith overrides only supplied fields', () {
      final updated = InstallProgress.initial.copyWith(
        stage: InstallStage.downloading,
        percent: 42,
        message: 'Downloading…',
      );
      expect(updated.stage, InstallStage.downloading);
      expect(updated.percent, 42);
      expect(updated.message, 'Downloading…');
      expect(updated.error, isNull);
    });

    test('copyWith preserves error when not supplied', () {
      final withError = InstallProgress.initial.copyWith(
        stage: InstallStage.error,
        percent: 0,
        message: 'Failed',
        error: 'network_error',
      );
      final copy = withError.copyWith(message: 'Retry…');
      expect(copy.error, 'network_error');
    });
  });

  group('DetectResult', () {
    test('enum has expected values', () {
      expect(
        DetectResult.values,
        containsAll([
          DetectResult.found,
          DetectResult.notFound,
          DetectResult.updateAvailable,
        ]),
      );
    });
  });

  group('VersionInfo', () {
    test('hasUpdate reflects version mismatch', () {
      const info = VersionInfo(
        installed: '1.0.0',
        latest: '1.1.0',
        hasUpdate: true,
      );
      expect(info.hasUpdate, isTrue);
      expect(info.installed, '1.0.0');
      expect(info.latest, '1.1.0');
    });
  });
}
