// ── Workflow sharing models & service ────────────────────────────────────────

/// Visibility level for a shared workflow.
enum WorkflowVisibility { team, public }

/// A link generated when sharing a workflow.
class ShareLink {
  const ShareLink({
    required this.url,
    required this.token,
    required this.expiresAt,
  });

  final String url;
  final String token;
  final DateTime? expiresAt;

  factory ShareLink.fromJson(Map<String, dynamic> json) => ShareLink(
        url: json['url'] as String? ?? '',
        token: json['token'] as String? ?? '',
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
      );
}

/// A workflow that has been shared to team or public.
class SharedWorkflow {
  const SharedWorkflow({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.authorAvatar,
    required this.downloads,
    required this.rating,
    required this.ratingCount,
    required this.visibility,
    required this.category,
    required this.skillCount,
    required this.agentCount,
    required this.hookCount,
    required this.createdAt,
    required this.tags,
  });

  final String id;
  final String name;
  final String description;
  final String author;
  final String authorAvatar;
  final int downloads;
  final double rating;
  final int ratingCount;
  final WorkflowVisibility visibility;
  final String category;
  final int skillCount;
  final int agentCount;
  final int hookCount;
  final DateTime createdAt;
  final List<String> tags;

  int get totalItems => skillCount + agentCount + hookCount;

  factory SharedWorkflow.fromJson(Map<String, dynamic> json) =>
      SharedWorkflow(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        author: json['author'] as String? ?? '',
        authorAvatar: json['author_avatar'] as String? ?? '',
        downloads: json['downloads'] as int? ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        ratingCount: json['rating_count'] as int? ?? 0,
        visibility: (json['visibility'] as String?) == 'public'
            ? WorkflowVisibility.public
            : WorkflowVisibility.team,
        category: json['category'] as String? ?? 'general',
        skillCount: json['skill_count'] as int? ?? 0,
        agentCount: json['agent_count'] as int? ?? 0,
        hookCount: json['hook_count'] as int? ?? 0,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
                DateTime.now(),
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

/// Filter for listing shared workflows.
class SharedWorkflowFilter {
  const SharedWorkflowFilter({
    this.query,
    this.category,
    this.visibility,
  });

  final String? query;
  final String? category;
  final WorkflowVisibility? visibility;
}

// ── Service ─────────────────────────────────────────────────────────────────

class WorkflowSharingService {
  const WorkflowSharingService();

  /// Shares a workflow with the given visibility, returning a share link.
  Future<ShareLink> shareWorkflow(
    String workflowId, {
    WorkflowVisibility visibility = WorkflowVisibility.team,
  }) async {
    // In production this calls the API. Returning mock data.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return ShareLink(
      url: 'https://orchestra.dev/workflows/shared/$workflowId',
      token: 'tok_${workflowId}_${DateTime.now().millisecondsSinceEpoch}',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  /// Imports a workflow from a share link.
  Future<SharedWorkflow> importWorkflow(String shareLink) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return SharedWorkflow(
      id: 'wf-imported',
      name: 'Imported Workflow',
      description: 'Workflow imported from share link',
      author: 'External',
      authorAvatar: 'EX',
      downloads: 0,
      rating: 0,
      ratingCount: 0,
      visibility: WorkflowVisibility.team,
      category: 'general',
      skillCount: 3,
      agentCount: 2,
      hookCount: 1,
      createdAt: DateTime.now(),
      tags: ['imported'],
    );
  }

  /// Lists shared workflows with optional filtering.
  Future<List<SharedWorkflow>> listSharedWorkflows({
    SharedWorkflowFilter filter = const SharedWorkflowFilter(),
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // Return mock marketplace data.
    var results = List<SharedWorkflow>.of(_mockSharedWorkflows);

    if (filter.query != null && filter.query!.isNotEmpty) {
      final q = filter.query!.toLowerCase();
      results = results
          .where((w) =>
              w.name.toLowerCase().contains(q) ||
              w.description.toLowerCase().contains(q) ||
              w.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }

    if (filter.category != null) {
      results =
          results.where((w) => w.category == filter.category).toList();
    }

    if (filter.visibility != null) {
      results = results
          .where((w) => w.visibility == filter.visibility)
          .toList();
    }

    return results;
  }
}

// ── Mock data ───────────────────────────────────────────────────────────────

final _mockSharedWorkflows = [
  SharedWorkflow(
    id: 'wf-001',
    name: 'Full-Stack TypeScript',
    description:
        'Complete workflow for TypeScript/React projects with QA testing, documentation, and CI/CD hooks.',
    author: 'Orchestra Team',
    authorAvatar: 'OT',
    downloads: 2847,
    rating: 4.8,
    ratingCount: 342,
    visibility: WorkflowVisibility.public,
    category: 'web',
    skillCount: 6,
    agentCount: 4,
    hookCount: 3,
    createdAt: DateTime.now().subtract(const Duration(days: 45)),
    tags: ['typescript', 'react', 'nextjs', 'fullstack'],
  ),
  SharedWorkflow(
    id: 'wf-002',
    name: 'Rust Systems',
    description:
        'Workflow for Rust systems programming with cargo integration, unsafe code review, and memory profiling agents.',
    author: 'Aisha Patel',
    authorAvatar: 'AP',
    downloads: 1203,
    rating: 4.6,
    ratingCount: 156,
    visibility: WorkflowVisibility.public,
    category: 'systems',
    skillCount: 4,
    agentCount: 3,
    hookCount: 2,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    tags: ['rust', 'systems', 'cargo', 'unsafe'],
  ),
  SharedWorkflow(
    id: 'wf-003',
    name: 'Go Microservices',
    description:
        'Optimized for Go microservice architectures with protobuf generation, Docker builds, and k8s deployment.',
    author: 'Marcus Rivera',
    authorAvatar: 'MR',
    downloads: 987,
    rating: 4.5,
    ratingCount: 128,
    visibility: WorkflowVisibility.public,
    category: 'backend',
    skillCount: 5,
    agentCount: 3,
    hookCount: 4,
    createdAt: DateTime.now().subtract(const Duration(days: 20)),
    tags: ['go', 'microservices', 'kubernetes', 'grpc'],
  ),
  SharedWorkflow(
    id: 'wf-004',
    name: 'Flutter Cross-Platform',
    description:
        'Flutter workflow with platform-specific agents for iOS, Android, macOS, web, and desktop.',
    author: 'Sarah Chen',
    authorAvatar: 'SC',
    downloads: 1645,
    rating: 4.9,
    ratingCount: 204,
    visibility: WorkflowVisibility.public,
    category: 'mobile',
    skillCount: 8,
    agentCount: 7,
    hookCount: 2,
    createdAt: DateTime.now().subtract(const Duration(days: 14)),
    tags: ['flutter', 'dart', 'mobile', 'cross-platform'],
  ),
  SharedWorkflow(
    id: 'wf-005',
    name: 'DevOps Pipeline',
    description:
        'CI/CD focused workflow with GitHub Actions, Docker, Terraform, and monitoring hooks.',
    author: 'James Wilson',
    authorAvatar: 'JW',
    downloads: 756,
    rating: 4.3,
    ratingCount: 89,
    visibility: WorkflowVisibility.public,
    category: 'devops',
    skillCount: 3,
    agentCount: 2,
    hookCount: 6,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    tags: ['devops', 'ci-cd', 'docker', 'terraform'],
  ),
  SharedWorkflow(
    id: 'wf-006',
    name: 'Team Sprint Kit',
    description:
        'Internal team workflow with sprint planning, code review delegation, and daily standup summaries.',
    author: 'Sarah Chen',
    authorAvatar: 'SC',
    downloads: 42,
    rating: 4.7,
    ratingCount: 12,
    visibility: WorkflowVisibility.team,
    category: 'management',
    skillCount: 3,
    agentCount: 2,
    hookCount: 1,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    tags: ['team', 'sprint', 'agile', 'management'],
  ),
  SharedWorkflow(
    id: 'wf-007',
    name: 'Python Data Science',
    description:
        'Workflow for Python data science projects with Jupyter notebook support, pandas agents, and ML model validation.',
    author: 'Orchestra Team',
    authorAvatar: 'OT',
    downloads: 2103,
    rating: 4.4,
    ratingCount: 267,
    visibility: WorkflowVisibility.public,
    category: 'data',
    skillCount: 5,
    agentCount: 4,
    hookCount: 2,
    createdAt: DateTime.now().subtract(const Duration(days: 60)),
    tags: ['python', 'data-science', 'ml', 'jupyter'],
  ),
  SharedWorkflow(
    id: 'wf-008',
    name: 'Swift/SwiftUI Native',
    description:
        'Apple platform workflow with SwiftUI previews, XCTest agents, and App Store submission hooks.',
    author: 'Aisha Patel',
    authorAvatar: 'AP',
    downloads: 891,
    rating: 4.7,
    ratingCount: 113,
    visibility: WorkflowVisibility.public,
    category: 'mobile',
    skillCount: 4,
    agentCount: 3,
    hookCount: 3,
    createdAt: DateTime.now().subtract(const Duration(days: 25)),
    tags: ['swift', 'swiftui', 'ios', 'macos'],
  ),
];
