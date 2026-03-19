/// The kind of terminal session.
enum TerminalSessionType { terminal, ssh, claude, remote }

/// Connection lifecycle state for a terminal session.
enum TerminalSessionStatus { connecting, connected, disconnected, error }

/// Immutable model representing a single terminal session.
class TerminalSessionModel {
  final String id;
  final TerminalSessionType type;
  final TerminalSessionStatus status;
  final String label;
  final DateTime createdAt;

  // SSH-specific (nullable)
  final String? sshHost;
  final String? sshUser;
  final int? sshPort;
  final String? sshPassword;
  final String? sshKeyFile;

  // Claude-specific (nullable)
  final String? claudeModel;
  final String? claudeSessionId;

  // Remote tunnel-specific (nullable)
  final String? remoteTunnelId;

  // Sidebar display
  final bool pinned;

  const TerminalSessionModel({
    required this.id,
    required this.type,
    required this.status,
    required this.label,
    required this.createdAt,
    this.sshHost,
    this.sshUser,
    this.sshPort,
    this.sshPassword,
    this.sshKeyFile,
    this.claudeModel,
    this.claudeSessionId,
    this.remoteTunnelId,
    this.pinned = false,
  });

  TerminalSessionModel copyWith({
    TerminalSessionStatus? status,
    String? label,
    String? claudeSessionId,
    String? remoteTunnelId,
    bool? pinned,
  }) {
    return TerminalSessionModel(
      id: id,
      type: type,
      status: status ?? this.status,
      label: label ?? this.label,
      createdAt: createdAt,
      sshHost: sshHost,
      sshUser: sshUser,
      sshPort: sshPort,
      sshPassword: sshPassword,
      sshKeyFile: sshKeyFile,
      claudeModel: claudeModel,
      claudeSessionId: claudeSessionId ?? this.claudeSessionId,
      remoteTunnelId: remoteTunnelId ?? this.remoteTunnelId,
      pinned: pinned ?? this.pinned,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerminalSessionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TerminalSessionModel(id: $id, type: $type, status: $status, label: $label)';
}
