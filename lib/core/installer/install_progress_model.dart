/// Stages of the Orchestra binary install / update flow.
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

/// Immutable snapshot of installer progress.
class InstallProgress {
  const InstallProgress({
    required this.stage,
    required this.percent,
    required this.message,
    this.error,
  });

  final InstallStage stage;

  /// Overall progress 0–100.
  final int percent;

  /// Human-readable status message.
  final String message;

  /// Non-null when [stage] == [InstallStage.error].
  final String? error;

  InstallProgress copyWith({
    InstallStage? stage,
    int? percent,
    String? message,
    String? error,
  }) {
    return InstallProgress(
      stage: stage ?? this.stage,
      percent: percent ?? this.percent,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }

  @override
  String toString() =>
      'InstallProgress(stage: $stage, percent: $percent%, message: $message'
      '${error != null ? ', error: $error' : ''})';
}
