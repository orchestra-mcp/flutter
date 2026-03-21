import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/features/devtools/providers/api_collection_provider.dart';

// ── API Collections selection ────────────────────────────────────────────────

class _SelectedCollectionId extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final selectedCollectionIdProvider =
    NotifierProvider<_SelectedCollectionId, String?>(_SelectedCollectionId.new);

class _SelectedEndpoint extends Notifier<ApiEndpoint?> {
  @override
  ApiEndpoint? build() => null;
  void select(ApiEndpoint? ep) => state = ep;
}

final selectedEndpointProvider =
    NotifierProvider<_SelectedEndpoint, ApiEndpoint?>(_SelectedEndpoint.new);

// ── Log Runner selection ─────────────────────────────────────────────────────

class _SelectedProcessId extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final selectedProcessIdProvider = NotifierProvider<_SelectedProcessId, String?>(
  _SelectedProcessId.new,
);

// ── Database Browser selection ───────────────────────────────────────────────

class _SelectedConnectionId extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final selectedConnectionIdProvider =
    NotifierProvider<_SelectedConnectionId, String?>(_SelectedConnectionId.new);

// ── Secrets selection ────────────────────────────────────────────────────────

class _SelectedSecretId extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final selectedSecretIdProvider = NotifierProvider<_SelectedSecretId, String?>(
  _SelectedSecretId.new,
);

// ── Prompts selection ────────────────────────────────────────────────────────

class _SelectedPromptId extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final selectedPromptIdProvider = NotifierProvider<_SelectedPromptId, String?>(
  _SelectedPromptId.new,
);
