import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/installer/install_progress_model.dart';

void main() {
  group('InstallProgress', () {
    test('constructs with required fields', () {
      const p = InstallProgress(
        stage: InstallStage.downloading,
        percent: 42,
        message: 'Downloading...',
      );
      expect(p.stage, InstallStage.downloading);
      expect(p.percent, 42);
      expect(p.message, 'Downloading...');
      expect(p.error, isNull);
    });

    test('copyWith overrides specified fields', () {
      const p = InstallProgress(
        stage: InstallStage.checking,
        percent: 0,
        message: 'Checking',
      );
      final p2 = p.copyWith(stage: InstallStage.done, percent: 100);
      expect(p2.stage, InstallStage.done);
      expect(p2.percent, 100);
      expect(p2.message, 'Checking'); // unchanged
    });

    test('error stage carries error message', () {
      const p = InstallProgress(
        stage: InstallStage.error,
        percent: 0,
        message: 'Failed',
        error: 'Network timeout',
      );
      expect(p.error, 'Network timeout');
    });

    test('toString includes stage and percent', () {
      const p = InstallProgress(
        stage: InstallStage.installing,
        percent: 75,
        message: 'Installing',
      );
      expect(p.toString(), contains('installing'));
      expect(p.toString(), contains('75'));
    });
  });

  group('InstallStage values', () {
    test('all expected stages exist', () {
      expect(InstallStage.values, containsAll([
        InstallStage.checking,
        InstallStage.fetchingVersion,
        InstallStage.downloading,
        InstallStage.extracting,
        InstallStage.installing,
        InstallStage.verifying,
        InstallStage.done,
        InstallStage.error,
      ]));
    });
  });
}
