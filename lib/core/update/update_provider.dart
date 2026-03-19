import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/update/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Current status of the update lifecycle.
enum UpdateStatus {
  idle,
  checking,
  available,
  downloading,
  readyToInstall,
  upToDate,
  error,
}

/// Immutable state for the update system.
class UpdateState {
  const UpdateState({
    this.status = UpdateStatus.idle,
    this.info,
    this.downloadProgress = 0.0,
    this.downloadedPath,
    this.error,
  });

  final UpdateStatus status;
  final UpdateInfo? info;
  final double downloadProgress;
  final String? downloadedPath;
  final String? error;

  UpdateState copyWith({
    UpdateStatus? status,
    UpdateInfo? info,
    double? downloadProgress,
    String? downloadedPath,
    String? error,
  }) {
    return UpdateState(
      status: status ?? this.status,
      info: info ?? this.info,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedPath: downloadedPath ?? this.downloadedPath,
      error: error ?? this.error,
    );
  }
}

/// Manages update checking, downloading, and installation.
///
/// Auto-checks on first build. Persists dismissed versions so the banner
/// doesn't nag after the user clicks "skip this version".
class UpdateNotifier extends Notifier<UpdateState> {
  static const _dismissedKey = 'update_dismissed_version';
  final _service = UpdateService();

  @override
  UpdateState build() {
    // Fire-and-forget background check on startup.
    Future.microtask(() => checkForUpdate());
    return const UpdateState();
  }

  /// Checks GitHub for a newer release. Non-blocking.
  Future<void> checkForUpdate() async {
    state = state.copyWith(status: UpdateStatus.checking);

    try {
      final info = await _service.checkForUpdate();

      if (!info.hasUpdate) {
        state = state.copyWith(status: UpdateStatus.upToDate, info: info);
        return;
      }

      // Check if user dismissed this version.
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getString(_dismissedKey);
      if (dismissed == info.latestVersion) {
        state = state.copyWith(status: UpdateStatus.upToDate, info: info);
        return;
      }

      state = state.copyWith(status: UpdateStatus.available, info: info);
    } catch (e) {
      state = state.copyWith(status: UpdateStatus.error, error: e.toString());
    }
  }

  /// Dismiss the current update — don't show the banner for this version.
  Future<void> dismiss() async {
    final version = state.info?.latestVersion;
    if (version != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedKey, version);
    }
    state = state.copyWith(status: UpdateStatus.upToDate);
  }

  /// Downloads and installs the update (desktop) or opens store (mobile).
  Future<void> install() async {
    final info = state.info;
    if (info == null) return;

    // Mobile: open store link.
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      final url = info.storeUrl;
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
      return;
    }

    // Desktop: download artifact.
    final downloadUrl = info.downloadUrl;
    if (downloadUrl == null) {
      state = state.copyWith(
        status: UpdateStatus.error,
        error: 'No download URL for this platform',
      );
      return;
    }

    state = state.copyWith(
      status: UpdateStatus.downloading,
      downloadProgress: 0.0,
    );

    try {
      final path = await _service.downloadUpdate(downloadUrl, (progress) {
        state = state.copyWith(downloadProgress: progress);
      });

      state = state.copyWith(
        status: UpdateStatus.readyToInstall,
        downloadedPath: path,
      );

      // Auto-open the artifact.
      await _service.installUpdate(path);
    } catch (e) {
      debugPrint('[Update] download failed: $e');
      state = state.copyWith(
        status: UpdateStatus.error,
        error: 'Download failed: $e',
      );
    }
  }
}

/// Global update provider — auto-checks on app startup.
final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(
  UpdateNotifier.new,
);
