import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/installer/install_progress_model.dart';

void main() {
  group('InstallProgress model', () {
    test('copyWith updates fields', () {
      const progress = InstallProgress(
        stage: InstallStage.downloading,
        percent: 10,
        message: 'Downloading...',
      );
      final updated = progress.copyWith(percent: 50);
      expect(updated.percent, 50);
      expect(updated.stage, InstallStage.downloading);
      expect(updated.message, 'Downloading...');
    });

    test('initial state is checking at 0%', () {
      expect(InstallProgress.initial.stage, InstallStage.checking);
      expect(InstallProgress.initial.percent, 0);
    });
  });

  group('DetectResult', () {
    test('enum has expected values', () {
      expect(DetectResult.values, containsAll([
        DetectResult.found,
        DetectResult.notFound,
        DetectResult.updateAvailable,
      ]));
    });
  });
}
