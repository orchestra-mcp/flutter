// ── Public sharing models & service ──────────────────────────────────────────

/// Options for creating a public share link.
class PublicShareOptions {
  const PublicShareOptions({
    this.expiresAt,
    this.password,
    this.allowedEntities = const ['features', 'notes', 'docs'],
  });

  final DateTime? expiresAt;
  final String? password;

  /// Which entity types are visible in the public view.
  final List<String> allowedEntities;
}

/// A generated public share link.
class PublicShareLink {
  const PublicShareLink({
    required this.id,
    required this.url,
    required this.shareToken,
    required this.projectId,
    required this.createdAt,
    this.expiresAt,
    this.hasPassword = false,
    this.allowedEntities = const ['features', 'notes', 'docs'],
  });

  final String id;
  final String url;
  final String shareToken;
  final String projectId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool hasPassword;
  final List<String> allowedEntities;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory PublicShareLink.fromJson(Map<String, dynamic> json) =>
      PublicShareLink(
        id: json['id'] as String? ?? '',
        url: json['url'] as String? ?? '',
        shareToken: json['share_token'] as String? ?? '',
        projectId: json['project_id'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
                DateTime.now(),
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
        hasPassword: json['has_password'] as bool? ?? false,
        allowedEntities: (json['allowed_entities'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['features', 'notes', 'docs'],
      );
}

/// A public project view returned when accessing a share link.
class PublicProject {
  const PublicProject({
    required this.id,
    required this.name,
    required this.description,
    required this.avatarUrl,
    required this.features,
    required this.notes,
    required this.docs,
  });

  final String id;
  final String name;
  final String description;
  final String avatarUrl;
  final List<PublicFeature> features;
  final List<PublicNote> notes;
  final List<PublicDoc> docs;

  factory PublicProject.fromJson(Map<String, dynamic> json) =>
      PublicProject(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
        features: (json['features'] as List<dynamic>?)
                ?.map(
                    (e) => PublicFeature.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        notes: (json['notes'] as List<dynamic>?)
                ?.map(
                    (e) => PublicNote.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        docs: (json['docs'] as List<dynamic>?)
                ?.map(
                    (e) => PublicDoc.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class PublicFeature {
  const PublicFeature({
    required this.id,
    required this.title,
    required this.status,
    required this.kind,
    this.description = '',
  });

  final String id;
  final String title;
  final String status;
  final String kind;
  final String description;

  factory PublicFeature.fromJson(Map<String, dynamic> json) =>
      PublicFeature(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        status: json['status'] as String? ?? 'todo',
        kind: json['kind'] as String? ?? 'feature',
        description: json['description'] as String? ?? '',
      );
}

class PublicNote {
  const PublicNote({
    required this.id,
    required this.title,
    this.content = '',
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;

  factory PublicNote.fromJson(Map<String, dynamic> json) => PublicNote(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        updatedAt:
            DateTime.tryParse(json['updated_at'] as String? ?? '') ??
                DateTime.now(),
      );
}

class PublicDoc {
  const PublicDoc({
    required this.id,
    required this.title,
    required this.path,
    this.content = '',
  });

  final String id;
  final String title;
  final String path;
  final String content;

  factory PublicDoc.fromJson(Map<String, dynamic> json) => PublicDoc(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        path: json['path'] as String? ?? '',
        content: json['content'] as String? ?? '',
      );
}

// ── Service ─────────────────────────────────────────────────────────────────

class PublicShareService {
  const PublicShareService();

  /// Creates a public share link for a project.
  Future<PublicShareLink> createPublicLink(
    String projectId, {
    PublicShareOptions options = const PublicShareOptions(),
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final token = 'pub_${projectId}_${DateTime.now().millisecondsSinceEpoch}';
    return PublicShareLink(
      id: 'psl-001',
      url: 'https://orchestra.dev/p/$token',
      shareToken: token,
      projectId: projectId,
      createdAt: DateTime.now(),
      expiresAt: options.expiresAt,
      hasPassword: options.password != null,
      allowedEntities: options.allowedEntities,
    );
  }

  /// Revokes an existing public share link.
  Future<void> revokePublicLink(String linkId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  /// Retrieves a public project view using a share token.
  Future<PublicProject> getPublicProject(String shareToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Return mock public project data.
    return _mockPublicProject;
  }
}

// ── Mock data ───────────────────────────────────────────────────────────────

final _mockPublicProject = PublicProject(
  id: 'proj-orchestra-agents',
  name: 'Orchestra Agents',
  description:
      'AI-powered project management framework with 290 MCP tools. '
      'Supports Claude Code, Cursor, VS Code, and more.',
  avatarUrl: '',
  features: [
    const PublicFeature(
      id: 'FEAT-BWL',
      title: 'Real-time Delegation Notifications',
      status: 'in-progress',
      kind: 'feature',
      description:
          'WebSocket-based delegation event listener with snackbar notifications and badge count.',
    ),
    const PublicFeature(
      id: 'FEAT-XND',
      title: 'Team Activity Feed',
      status: 'in-progress',
      kind: 'feature',
      description:
          'Full-screen timeline of team activities with filters and real-time updates.',
    ),
    const PublicFeature(
      id: 'FEAT-IGV',
      title: 'Connected Tunnels Dashboard',
      status: 'todo',
      kind: 'feature',
      description:
          'Dashboard showing connected desktop QUIC clients with live status indicators.',
    ),
    const PublicFeature(
      id: 'FEAT-KTT',
      title: 'Workflow Generator',
      status: 'done',
      kind: 'chore',
      description:
          'Service to generate CLAUDE.md and AGENTS.md from structured configuration.',
    ),
    const PublicFeature(
      id: 'FEAT-UJV',
      title: 'Web-specific Architecture',
      status: 'done',
      kind: 'feature',
      description:
          'Responsive web shell with NavigationRail and BottomNavigationBar.',
    ),
    const PublicFeature(
      id: 'FEAT-FRU',
      title: 'Web App Shell',
      status: 'done',
      kind: 'feature',
      description: 'Adaptive layout with breakpoint-aware navigation.',
    ),
    const PublicFeature(
      id: 'FEAT-HUF',
      title: 'Public Marketing Pages',
      status: 'in-testing',
      kind: 'feature',
      description:
          'Landing page, pricing page, and download page for the public website.',
    ),
  ],
  notes: [
    PublicNote(
      id: 'note-001',
      title: 'Architecture Decision: QUIC vs gRPC',
      content:
          'After benchmarking, QUIC with length-delimited Protobuf provides '
          'lower latency and simpler connection management for our use case. '
          'gRPC adds unnecessary HTTP/2 framing overhead.',
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    PublicNote(
      id: 'note-002',
      title: 'Flutter Web Performance Notes',
      content:
          'CanvasKit renderer preferred for complex UIs. HTML renderer for '
          'SEO-critical marketing pages. Use deferred loading for heavy screens.',
      updatedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ],
  docs: [
    const PublicDoc(
      id: 'doc-001',
      title: 'API Reference',
      path: 'docs/api-reference.md',
      content:
          'Complete API reference for Orchestra MCP tools. '
          '290 tools across 36 plugins.',
    ),
    const PublicDoc(
      id: 'doc-002',
      title: 'Delegation Guide',
      path: 'docs/delegation.md',
      content:
          'Guide to using the delegation system for cross-team feature handoffs.',
    ),
  ],
);
