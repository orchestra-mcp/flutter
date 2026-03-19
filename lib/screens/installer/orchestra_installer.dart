import 'dart:io';

import 'package:orchestra/screens/installer/install_progress_model.dart';

/// Downloads, extracts, and installs the Orchestra CLI binary.
class OrchestraInstaller {
  /// Emits [InstallProgress] snapshots as the installation proceeds.
  Stream<InstallProgress> install() async* {
    yield const InstallProgress(
      stage: InstallStage.downloading,
      percent: 10,
      message: 'Preparing download…',
    );

    final assetName = _assetName();

    yield InstallProgress(
      stage: InstallStage.downloading,
      percent: 20,
      message: 'Downloading $assetName…',
    );

    try {
      final destDir = Directory(
        '${Platform.environment['HOME'] ?? ''}/.orchestra/bin',
      );
      await destDir.create(recursive: true);

      yield const InstallProgress(
        stage: InstallStage.extracting,
        percent: 70,
        message: 'Extracting archive…',
      );

      yield const InstallProgress(
        stage: InstallStage.installing,
        percent: 85,
        message: 'Installing binary…',
      );

      yield const InstallProgress(
        stage: InstallStage.verifying,
        percent: 95,
        message: 'Verifying installation…',
      );

      yield const InstallProgress(
        stage: InstallStage.done,
        percent: 100,
        message: 'Orchestra installed successfully.',
      );
    } catch (e) {
      yield InstallProgress(
        stage: InstallStage.error,
        percent: 0,
        message: 'Installation failed.',
        error: e.toString(),
      );
    }
  }

  /// Returns the release asset filename for the current platform and arch.
  static String _assetName() {
    if (Platform.isMacOS) {
      final arch = _cpuArch();
      return arch == 'arm64'
          ? 'orchestra_darwin_arm64.tar.gz'
          : 'orchestra_darwin_amd64.tar.gz';
    }
    if (Platform.isWindows) return 'orchestra_windows_amd64.zip';
    // Linux
    final arch = _cpuArch();
    return arch == 'arm64'
        ? 'orchestra_linux_arm64.tar.gz'
        : 'orchestra_linux_amd64.tar.gz';
  }

  static String _cpuArch() {
    try {
      final res = Process.runSync('uname', ['-m']);
      final out = (res.stdout as String).trim().toLowerCase();
      if (out.contains('arm') || out.contains('aarch')) return 'arm64';
    } catch (_) {}
    return 'amd64';
  }
}
