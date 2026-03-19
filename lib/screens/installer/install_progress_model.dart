/// Stages of the Orchestra binary installer.
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

/// Snapshot of installer progress passed to the UI.
class InstallProgress {
  const InstallProgress({
    required this.stage,
    this.percent = 0,
    this.message = '',
    this.error,
  });

  final InstallStage stage;

  /// Completion percentage 0–100.
  final int percent;

  /// Human-readable status line shown in the progress card.
  final String message;

  /// Non-null when [stage] == [InstallStage.error].
  final String? error;

  InstallProgress copyWith({
    InstallStage? stage,
    int? percent,
    String? message,
    String? error,
  }) => InstallProgress(
    stage: stage ?? this.stage,
    percent: percent ?? this.percent,
    message: message ?? this.message,
    error: error ?? this.error,
  );
}
