/// Install stage and progress model for the Orchestra desktop installer.
enum InstallStage {
  checking,
  fetchingVersion,
  downloading,
  extracting,
  installing,
  verifying,
  done,
  error,
}

class InstallProgress {
  const InstallProgress({
    required this.stage,
    required this.percent,
    required this.message,
    this.error,
  });

  final InstallStage stage;

  /// Progress 0–100.
  final int percent;

  final String message;

  /// Non-null when [stage] is [InstallStage.error].
  final String? error;

  InstallProgress copyWith({
    InstallStage? stage,
    int? percent,
    String? message,
    String? error,
  }) =>
      InstallProgress(
        stage: stage ?? this.stage,
        percent: percent ?? this.percent,
        message: message ?? this.message,
        error: error ?? this.error,
      );

  static const initial = InstallProgress(
    stage: InstallStage.checking,
    percent: 0,
    message: 'Checking for Orchestra...',
  );
}

/// Detect result returned by [OrchestraDetector.check].
enum DetectResult { found, notFound, updateAvailable }

/// Version info returned by [OrchestraDetector.getVersions].
class VersionInfo {
  const VersionInfo({
    required this.installed,
    required this.latest,
    required this.hasUpdate,
  });

  final String installed;
  final String latest;
  final bool hasUpdate;
}
