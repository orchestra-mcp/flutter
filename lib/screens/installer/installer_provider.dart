import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/screens/installer/install_progress_model.dart';
import 'package:orchestra/screens/installer/orchestra_detector.dart';
import 'package:orchestra/screens/installer/orchestra_installer.dart';

/// Manages the full installer state machine.
class InstallerNotifier extends AsyncNotifier<InstallProgress> {
  @override
  Future<InstallProgress> build() async {
    return const InstallProgress(
      stage: InstallStage.checking,
      percent: 0,
      message: 'Checking for existing installation…',
    );
  }

  /// Runs the full detection → install flow, emitting progress snapshots.
  Future<void> startInstall() async {
    final detector = OrchestraDetector();
    final detected = await detector.check();

    if (detected == DetectResult.found) {
      state = const AsyncData(
        InstallProgress(
          stage: InstallStage.done,
          percent: 100,
          message: 'Orchestra is already installed.',
        ),
      );
      return;
    }

    final installer = OrchestraInstaller();
    await for (final progress in installer.install()) {
      state = AsyncData(progress);
    }
  }
}

final installerProvider =
    AsyncNotifierProvider<InstallerNotifier, InstallProgress>(
  InstallerNotifier.new,
);
