import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/storage/repositories/project_repository.dart';
import 'package:orchestra/core/storage/storage_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_list_tile.dart';

// -- Screen ------------------------------------------------------------------

/// Project detail screen with tabs: Features, Plans, Requests, Persons.
class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with TickerProviderStateMixin {
  static const _tabCount = 4;

  static List<String> _tabs(AppLocalizations l10n) => [
    l10n.features,
    l10n.plans,
    l10n.requests,
    l10n.persons,
  ];

  late final TabController _tabController;
  String? _projectSlug;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _resolveSlug();
  }

  /// Resolve the project slug from the UUID for querying sub-entities.
  /// Features/plans/requests/persons use project_slug, not the UUID id.
  Future<void> _resolveSlug() async {
    final db = ref.read(powersyncDatabaseProvider);
    final row = await db.getOptional(
      'SELECT slug, name FROM projects WHERE id = ?',
      [widget.projectId],
    );
    if (row != null && mounted) {
      // Prefer slug, fall back to name, then to the raw projectId.
      final slug =
          (row['slug'] as String?) ??
          (row['name'] as String?) ??
          widget.projectId;
      setState(() => _projectSlug = slug);
    } else if (mounted) {
      setState(() => _projectSlug = widget.projectId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    // Use resolved slug for sub-entity queries, fallback to projectId.
    final slug = _projectSlug ?? widget.projectId;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          _ProjectHeader(projectId: widget.projectId, tokens: tokens),
          _DetailTabBar(
            controller: _tabController,
            tokens: tokens,
            tabs: _tabs(AppLocalizations.of(context)),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FeaturesTab(projectId: slug, tokens: tokens),
                _PlansTab(projectId: slug, tokens: tokens),
                _RequestsTab(projectId: slug, tokens: tokens),
                _PersonsTab(projectId: slug, tokens: tokens),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -- Header ------------------------------------------------------------------

class _ProjectHeader extends ConsumerWidget {
  const _ProjectHeader({required this.projectId, required this.tokens});

  final String projectId;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Project?>(
      future: ref.read(projectRepositoryProvider).getById(projectId),
      builder: (context, snapshot) {
        final project = snapshot.data;
        final displayName = project?.name ?? projectId;
        final subtitle =
            project?.description ??
            AppLocalizations.of(context).managedByOrchestra;

        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Semantics(
                      label: AppLocalizations.of(context).goBack,
                      button: true,
                      child: GestureDetector(
                        onTap: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            context.go(Routes.projects);
                          }
                        },
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: tokens.fgBright,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 34),
                  child: Text(
                    subtitle,
                    style: TextStyle(color: tokens.fgMuted, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// -- Tab bar -----------------------------------------------------------------

class _DetailTabBar extends StatelessWidget {
  const _DetailTabBar({
    required this.controller,
    required this.tokens,
    required this.tabs,
  });

  final TabController controller;
  final OrchestraColorTokens tokens;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: tokens.accent,
        indicatorWeight: 2,
        labelColor: tokens.accent,
        unselectedLabelColor: tokens.fgMuted,
        dividerColor: tokens.border.withValues(alpha: 0.3),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }
}

// -- Features tab ------------------------------------------------------------

class _FeaturesTab extends ConsumerWidget {
  const _FeaturesTab({required this.projectId, required this.tokens});

  final String projectId;
  final OrchestraColorTokens tokens;

  Color _statusColor(String status) => switch (status) {
    'done' => const Color(0xFF4ADE80),
    'in-progress' => tokens.accent,
    'in-review' => const Color(0xFFFBBF24),
    'in-testing' => const Color(0xFF38BDF8),
    _ => tokens.fgDim,
  };

  IconData _statusIcon(String status) => switch (status) {
    'done' => Icons.check_circle_rounded,
    'in-progress' => Icons.play_circle_rounded,
    'in-review' => Icons.rate_review_rounded,
    'in-testing' => Icons.science_rounded,
    _ => Icons.radio_button_unchecked_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(powersyncDatabaseProvider);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.getAll(
        'SELECT * FROM features WHERE project_slug = ? ORDER BY updated_at DESC',
        [projectId],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: tokens.accent));
        }
        if (snapshot.hasError) {
          return _ErrorTab(error: snapshot.error.toString(), tokens: tokens);
        }
        final features = snapshot.data ?? [];
        if (features.isEmpty) {
          return _EmptyTab(
            icon: Icons.checklist_rounded,
            label: AppLocalizations.of(context).noFeatures,
            tokens: tokens,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: features.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final f = features[index];
            final id = f['id']?.toString() ?? '';
            final title = f['title']?.toString() ?? id;
            final status = f['status']?.toString() ?? 'todo';
            return GlassListTile(
              leadingIcon: _statusIcon(status),
              leadingColor: _statusColor(status),
              label: id,
              description: '$title — $status',
              onTap: () => context.push(Routes.projectFeature(projectId, id)),
            );
          },
        );
      },
    );
  }
}

// -- Plans tab ---------------------------------------------------------------

class _PlansTab extends ConsumerWidget {
  const _PlansTab({required this.projectId, required this.tokens});

  final String projectId;
  final OrchestraColorTokens tokens;

  Color _statusColor(String status) => switch (status) {
    'approved' => const Color(0xFF4ADE80),
    'in-progress' => tokens.accent,
    'completed' => const Color(0xFF4ADE80),
    'draft' => tokens.fgDim,
    _ => tokens.fgDim,
  };

  IconData _statusIcon(String status) => switch (status) {
    'approved' => Icons.check_circle_outline_rounded,
    'in-progress' => Icons.play_circle_rounded,
    'completed' => Icons.check_circle_rounded,
    'draft' => Icons.edit_note_rounded,
    _ => Icons.description_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(powersyncDatabaseProvider);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.getAll(
        'SELECT * FROM plans WHERE project_slug = ? ORDER BY updated_at DESC',
        [projectId],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: tokens.accent));
        }
        if (snapshot.hasError) {
          return _ErrorTab(error: snapshot.error.toString(), tokens: tokens);
        }
        final plans = snapshot.data ?? [];
        if (plans.isEmpty) {
          return _EmptyTab(
            icon: Icons.map_rounded,
            label: AppLocalizations.of(context).noPlans,
            tokens: tokens,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: plans.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final p = plans[index];
            final id = p['id']?.toString() ?? '';
            final title = p['title']?.toString() ?? id;
            final status = p['status']?.toString() ?? 'draft';
            return GlassListTile(
              leadingIcon: _statusIcon(status),
              leadingColor: _statusColor(status),
              label: id,
              description: '$title — $status',
              onTap: () => context.push(Routes.projectPlan(projectId, id)),
            );
          },
        );
      },
    );
  }
}

// -- Requests tab ------------------------------------------------------------

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab({required this.projectId, required this.tokens});

  final String projectId;
  final OrchestraColorTokens tokens;

  Color _kindColor(String kind) => switch (kind) {
    'bug' => const Color(0xFFEF4444),
    'hotfix' => const Color(0xFFF97316),
    'feature' => tokens.accent,
    _ => tokens.fgDim,
  };

  IconData _kindIcon(String kind) => switch (kind) {
    'bug' => Icons.bug_report_rounded,
    'hotfix' => Icons.local_fire_department_rounded,
    'feature' => Icons.auto_awesome_rounded,
    _ => Icons.inbox_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(powersyncDatabaseProvider);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.getAll(
        'SELECT * FROM requests WHERE project_slug = ? ORDER BY updated_at DESC',
        [projectId],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: tokens.accent));
        }
        if (snapshot.hasError) {
          return _ErrorTab(error: snapshot.error.toString(), tokens: tokens);
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return _EmptyTab(
            icon: Icons.inbox_rounded,
            label: AppLocalizations.of(context).noRequests,
            tokens: tokens,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final r = requests[index];
            final id = r['id']?.toString() ?? '';
            final title = r['title']?.toString() ?? id;
            final kind = r['kind']?.toString() ?? 'feature';
            return GlassListTile(
              leadingIcon: _kindIcon(kind),
              leadingColor: _kindColor(kind),
              label: id,
              description: '$title — $kind',
              onTap: () => context.push(Routes.projectRequest(projectId, id)),
            );
          },
        );
      },
    );
  }
}

// -- Persons tab -------------------------------------------------------------

class _PersonsTab extends ConsumerWidget {
  const _PersonsTab({required this.projectId, required this.tokens});

  final String projectId;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(powersyncDatabaseProvider);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.getAll(
        'SELECT * FROM persons WHERE project_slug = ? ORDER BY updated_at DESC',
        [projectId],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: tokens.accent));
        }
        if (snapshot.hasError) {
          return _ErrorTab(error: snapshot.error.toString(), tokens: tokens);
        }
        final persons = snapshot.data ?? [];
        if (persons.isEmpty) {
          return _EmptyTab(
            icon: Icons.people_rounded,
            label: AppLocalizations.of(context).noPersons,
            tokens: tokens,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: persons.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final p = persons[index];
            final id = p['id']?.toString() ?? '';
            final name = p['name']?.toString() ?? id;
            final role = p['role']?.toString() ?? '';
            return GlassListTile(
              leadingIcon: Icons.person_rounded,
              leadingColor: tokens.accent,
              label: name,
              description: role.isNotEmpty ? role : id,
              onTap: () => context.push(Routes.projectPerson(projectId, id)),
            );
          },
        );
      },
    );
  }
}

// -- Empty state helper ------------------------------------------------------

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.label,
    required this.tokens,
  });

  final IconData icon;
  final String label;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tokens.fgDim, size: 48),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: tokens.fgMuted, fontSize: 15)),
        ],
      ),
    );
  }
}

// -- Error state helper ------------------------------------------------------

class _ErrorTab extends StatelessWidget {
  const _ErrorTab({required this.error, required this.tokens});

  final String error;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: tokens.fgDim, size: 48),
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(color: tokens.fgMuted, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
