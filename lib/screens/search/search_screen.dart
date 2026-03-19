import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';
import 'package:orchestra/widgets/glass_list_tile.dart';

// -- Entity categories for browse mode ----------------------------------------

class _EntityCategory {
  const _EntityCategory({
    required this.labelKey,
    required this.icon,
    required this.color,
    required this.route,
    required this.scope,
    required this.subtitleKey,
  });

  final String labelKey;
  final IconData icon;
  final Color color;
  final String route;
  final String scope;
  final String subtitleKey;
}

const _entityCategories = <_EntityCategory>[
  _EntityCategory(labelKey: 'projects', icon: Icons.folder_rounded, color: Color(0xFF38BDF8), route: Routes.projects, scope: 'projects', subtitleKey: 'subtitleProjects'),
  _EntityCategory(labelKey: 'notes', icon: Icons.sticky_note_2_rounded, color: Color(0xFFFBBF24), route: Routes.notes, scope: 'notes', subtitleKey: 'subtitleNotes'),
  _EntityCategory(labelKey: 'agents', icon: Icons.smart_toy_rounded, color: Color(0xFF4ADE80), route: Routes.agents, scope: 'agents', subtitleKey: 'subtitleAgents'),
  _EntityCategory(labelKey: 'skills', icon: Icons.bolt_rounded, color: Color(0xFFF97316), route: Routes.skills, scope: 'skills', subtitleKey: 'subtitleSkills'),
  _EntityCategory(labelKey: 'workflows', icon: Icons.account_tree_rounded, color: Color(0xFF818CF8), route: Routes.workflows, scope: 'workflows', subtitleKey: 'subtitleWorkflows'),
  _EntityCategory(labelKey: 'docs', icon: Icons.menu_book_rounded, color: Color(0xFF06B6D4), route: Routes.docs, scope: 'docs', subtitleKey: 'subtitleDocs'),
  _EntityCategory(labelKey: 'delegations', icon: Icons.sync_alt_rounded, color: Color(0xFFA78BFA), route: Routes.delegations, scope: 'delegations', subtitleKey: 'subtitleDelegations'),
  _EntityCategory(labelKey: 'healthScore', icon: Icons.favorite_rounded, color: Color(0xFFEF4444), route: Routes.healthScore, scope: 'health', subtitleKey: 'subtitleHealthScore'),
  _EntityCategory(labelKey: 'vitals', icon: Icons.monitor_heart_rounded, color: Color(0xFFF43F5E), route: Routes.healthVitals, scope: 'health', subtitleKey: 'subtitleVitals'),
  _EntityCategory(labelKey: 'dailyFlow', icon: Icons.auto_graph_rounded, color: Color(0xFF818CF8), route: Routes.healthFlow, scope: 'health', subtitleKey: 'subtitleDailyFlow'),
  _EntityCategory(labelKey: 'hydration', icon: Icons.water_drop_rounded, color: Color(0xFF38BDF8), route: Routes.healthHydration, scope: 'health', subtitleKey: 'subtitleHydration'),
  _EntityCategory(labelKey: 'caffeine', icon: Icons.coffee_rounded, color: Color(0xFFF97316), route: Routes.healthCaffeine, scope: 'health', subtitleKey: 'subtitleCaffeine'),
  _EntityCategory(labelKey: 'nutrition', icon: Icons.restaurant_rounded, color: Color(0xFF4ADE80), route: Routes.healthNutrition, scope: 'health', subtitleKey: 'subtitleNutrition'),
  _EntityCategory(labelKey: 'pomodoro', icon: Icons.timer_rounded, color: Color(0xFFF97316), route: Routes.healthPomodoro, scope: 'health', subtitleKey: 'subtitlePomodoro'),
  _EntityCategory(labelKey: 'shutdown', icon: Icons.nightlight_rounded, color: Color(0xFF6366F1), route: Routes.healthShutdown, scope: 'health', subtitleKey: 'subtitleShutdown'),
  _EntityCategory(labelKey: 'weight', icon: Icons.monitor_weight_rounded, color: Color(0xFF14B8A6), route: Routes.healthWeight, scope: 'health', subtitleKey: 'subtitleWeight'),
  _EntityCategory(labelKey: 'sleep', icon: Icons.bedtime_rounded, color: Color(0xFF8B5CF6), route: Routes.healthSleep, scope: 'health', subtitleKey: 'subtitleSleep'),
];

String _resolveLabel(AppLocalizations l10n, String key) => switch (key) {
  'projects' => l10n.projects,
  'notes' => l10n.notes,
  'agents' => l10n.agents,
  'skills' => l10n.skills,
  'workflows' => l10n.workflows,
  'docs' => l10n.docs,
  'delegations' => l10n.delegations,
  'healthScore' => l10n.healthScore,
  'vitals' => l10n.vitals,
  'dailyFlow' => l10n.dailyFlow,
  'hydration' => l10n.hydration,
  'caffeine' => l10n.caffeine,
  'nutrition' => l10n.nutrition,
  'pomodoro' => l10n.pomodoro,
  'shutdown' => l10n.shutdown,
  'weight' => l10n.weight,
  'sleep' => l10n.sleep,
  'features' => l10n.features,
  'sessions' => l10n.sessions,
  _ => key,
};

String _resolveSubtitle(AppLocalizations l10n, String key) => switch (key) {
  'subtitleProjects' => l10n.subtitleProjects,
  'subtitleNotes' => l10n.subtitleNotes,
  'subtitleAgents' => l10n.subtitleAgents,
  'subtitleSkills' => l10n.subtitleSkills,
  'subtitleWorkflows' => l10n.subtitleWorkflows,
  'subtitleDocs' => l10n.subtitleDocs,
  'subtitleDelegations' => l10n.subtitleDelegations,
  'subtitleHealthScore' => l10n.subtitleHealthScore,
  'subtitleVitals' => l10n.subtitleVitals,
  'subtitleDailyFlow' => l10n.subtitleDailyFlow,
  'subtitleHydration' => l10n.subtitleHydration,
  'subtitleCaffeine' => l10n.subtitleCaffeine,
  'subtitleNutrition' => l10n.subtitleNutrition,
  'subtitlePomodoro' => l10n.subtitlePomodoro,
  'subtitleShutdown' => l10n.subtitleShutdown,
  'subtitleWeight' => l10n.subtitleWeight,
  'subtitleSleep' => l10n.subtitleSleep,
  _ => key,
};

// -- Search category enum & labels -------------------------------------------

enum SearchCategory {
  all,
  projects,
  features,
  notes,
  agents,
  skills,
  workflows,
  docs,
  sessions,
}

Map<SearchCategory, String> _categoryLabels(AppLocalizations l10n) => {
  SearchCategory.all: l10n.all,
  SearchCategory.projects: l10n.projects,
  SearchCategory.features: l10n.features,
  SearchCategory.notes: l10n.notes,
  SearchCategory.agents: l10n.agents,
  SearchCategory.skills: l10n.skills,
  SearchCategory.workflows: l10n.workflows,
  SearchCategory.docs: l10n.docs,
  SearchCategory.sessions: l10n.sessions,
};

// -- Search result item model ------------------------------------------------

class _SearchResultItem {
  _SearchResultItem({
    required this.type,
    required this.title,
    required this.subtitle,
    this.id,
  });

  final String type;
  final String title;
  final String subtitle;
  final String? id;

  IconData get icon => switch (type) {
        'project' => Icons.folder_rounded,
        'feature' => Icons.auto_awesome_rounded,
        'note' => Icons.sticky_note_2_rounded,
        'agent' => Icons.smart_toy_rounded,
        'skill' => Icons.bolt_rounded,
        'workflow' => Icons.account_tree_rounded,
        'doc' => Icons.description_rounded,
        'session' => Icons.terminal_rounded,
        _ => Icons.search_rounded,
      };

  Color get iconColor => switch (type) {
        'project' => const Color(0xFF38BDF8),
        'feature' => const Color(0xFFA78BFA),
        'note' => const Color(0xFFFBBF24),
        'agent' => const Color(0xFF4ADE80),
        'skill' => const Color(0xFFF97316),
        'workflow' => const Color(0xFFEC4899),
        'doc' => const Color(0xFF60A5FA),
        'session' => const Color(0xFF94A3B8),
        _ => const Color(0xFF94A3B8),
      };
}

// -- Screen ------------------------------------------------------------------

/// Search screen with two modes:
/// 1. Browse mode (no query): shows grid of entity categories
/// 2. Search mode (has query): global search across all resources
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  SearchCategory _selectedCategory = SearchCategory.all;
  bool _isLoading = false;
  String? _error;
  List<_SearchResultItem> _results = [];
  Timer? _debounce;

  String? _scopeFromCategory(SearchCategory cat) => switch (cat) {
        SearchCategory.all => null,
        SearchCategory.projects => 'projects',
        SearchCategory.features => 'features',
        SearchCategory.notes => 'notes',
        SearchCategory.agents => 'agents',
        SearchCategory.skills => 'skills',
        SearchCategory.workflows => 'workflows',
        SearchCategory.docs => 'docs',
        SearchCategory.sessions => 'sessions',
      };

  bool get _hasQuery => _controller.text.trim().isNotEmpty;

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query.trim());
      } else {
        setState(() {
          _results = [];
          _error = null;
        });
      }
    });
    // Trigger rebuild to switch between browse/search mode.
    setState(() {});
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final scope = _scopeFromCategory(_selectedCategory);
      final response =
          await ref.read(apiClientProvider).search(query, scope: scope);

      final rawResults = response['results'];
      final List<_SearchResultItem> items = [];
      if (rawResults is List) {
        for (final entry in rawResults) {
          if (entry is Map<String, dynamic>) {
            items.add(_SearchResultItem(
              type: (entry['type'] as String?) ?? '',
              title: (entry['title'] as String?) ??
                  (entry['name'] as String?) ??
                  '',
              subtitle: (entry['subtitle'] as String?) ??
                  (entry['description'] as String?) ??
                  '',
              id: entry['id']?.toString(),
            ));
          }
        }
      }

      if (mounted) {
        setState(() {
          _results = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _selectCategory(SearchCategory cat) {
    setState(() => _selectedCategory = cat);
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      _performSearch(query);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final catLabels = _categoryLabels(l10n);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            // -- Header with search field ------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _GlassSearchField(
                      controller: _controller,
                      tokens: tokens,
                      onChanged: _onQueryChanged,
                      placeholder: l10n.searchEverything,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    label: l10n.closeSearch,
                    child: GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.go(Routes.summary);
                        }
                      },
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(
                          color: tokens.accent,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // -- Category chips (only shown when searching) ------------------
            if (_hasQuery)
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: SearchCategory.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = SearchCategory.values[index];
                    final isSelected = cat == _selectedCategory;
                    return _CategoryChip(
                      label: catLabels[cat]!,
                      isSelected: isSelected,
                      tokens: tokens,
                      onTap: () => _selectCategory(cat),
                    );
                  },
                ),
              ),

            if (_hasQuery) const SizedBox(height: 12),

            // -- Content: browse or search results ---------------------------
            Expanded(
              child: _hasQuery ? _buildSearchResults(tokens, l10n) : _buildBrowse(tokens, l10n),
            ),
          ],
        ),
      ),
    );
  }

  /// Entity category grid (browse mode — no query).
  Widget _buildBrowse(OrchestraColorTokens tokens, AppLocalizations l10n) {
    final isWide = MediaQuery.sizeOf(context).width > 600;
    final crossAxisCount = isWide ? 3 : 2;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: _entityCategories.length,
      itemBuilder: (context, index) {
        final cat = _entityCategories[index];
        return _EntityCategoryCard(
          label: _resolveLabel(l10n, cat.labelKey),
          subtitle: _resolveSubtitle(l10n, cat.subtitleKey),
          icon: cat.icon,
          color: cat.color,
          tokens: tokens,
          onTap: () => context.go(cat.route),
        );
      },
    );
  }

  /// Search results list (search mode — has query).
  Widget _buildSearchResults(OrchestraColorTokens tokens, AppLocalizations l10n) {
    if (_isLoading) return _LoadingState(tokens: tokens);
    if (_error != null) return _ErrorState(tokens: tokens, message: _error!, l10n: l10n);
    if (_results.isEmpty) {
      return _EmptyState(tokens: tokens, hasQuery: true, l10n: l10n);
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final r = _results[index];
        return GlassListTile(
          leadingIcon: r.icon,
          leadingColor: r.iconColor,
          label: r.title,
          description: r.subtitle,
          onTap: () {
            // TODO(search): Navigate to result detail.
          },
        );
      },
    );
  }
}

// -- Entity category card (browse mode) ---------------------------------------

class _EntityCategoryCard extends StatelessWidget {
  const _EntityCategoryCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label category',
      button: true,
      child: GlassCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: tokens.fgDim, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// -- Glass search text field -------------------------------------------------

class _GlassSearchField extends StatelessWidget {
  const _GlassSearchField({
    required this.controller,
    required this.tokens,
    required this.onChanged,
    required this.placeholder,
  });

  final TextEditingController controller;
  final OrchestraColorTokens tokens;
  final ValueChanged<String> onChanged;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: placeholder,
      textField: true,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: tokens.bgAlt.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tokens.borderFaint,
            width: 0.5,
          ),
        ),
        child: TextField(
          controller: controller,
          autofocus: true,
          onChanged: onChanged,
          style: TextStyle(color: tokens.fgBright, fontSize: 15),
          cursorColor: tokens.accent,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: tokens.fgDim, fontSize: 15),
            prefixIcon: Icon(Icons.search_rounded,
                color: tokens.fgMuted, size: 20),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

// -- Category chip -----------------------------------------------------------

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label category filter',
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? tokens.accent.withValues(alpha: 0.20)
                : tokens.bgAlt.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? tokens.accent.withValues(alpha: 0.50)
                  : tokens.borderFaint,
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? tokens.accent : tokens.fgMuted,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// -- Loading state -----------------------------------------------------------

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: tokens.accent,
        ),
      ),
    );
  }
}

// -- Error state -------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.tokens, required this.message, required this.l10n});
  final OrchestraColorTokens tokens;
  final String message;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: tokens.fgDim),
              const SizedBox(height: 16),
              Text(
                l10n.searchFailed,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(color: tokens.fgMuted, fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- Empty state -------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.tokens,
    required this.hasQuery,
    required this.l10n,
  });

  final OrchestraColorTokens tokens;
  final bool hasQuery;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasQuery
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
                size: 48,
                color: tokens.fgDim,
              ),
              const SizedBox(height: 16),
              Text(
                hasQuery ? l10n.noResults : l10n.browseResources,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasQuery
                    ? l10n.tryAdjustingQuery
                    : l10n.tapCategoryToExplore,
                style: TextStyle(color: tokens.fgMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
