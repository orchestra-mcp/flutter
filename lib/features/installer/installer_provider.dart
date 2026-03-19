import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/features/installer/install_progress_model.dart';
import 'package:orchestra/features/installer/orchestra_installer.dart';

/// Riverpod notifier that drives the installer state machine.
class InstallerNotifier extends AsyncNotifier<InstallProgress> {
  @override
  Future<InstallProgress> build() async => InstallProgress.initial;

  Future<void> startInstall() async {
    state = const AsyncValue.loading();
    final installer = OrchestraInstaller();
    await installer.install(
      onProgress: (progress) {
        state = AsyncValue.data(progress);
      },
    );
  }
}

final installerProvider =
    AsyncNotifierProvider<InstallerNotifier, InstallProgress>(
  InstallerNotifier.new,
);
