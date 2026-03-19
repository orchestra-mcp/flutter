import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/ws/ws_manager.dart';

final wsManagerProvider = Provider<WsManager>((ref) {
  final manager = WsManager(ref: ref);
  ref.onDispose(manager.dispose);
  return manager;
});
