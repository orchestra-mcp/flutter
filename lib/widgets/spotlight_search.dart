import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/i18n/rtl_utils.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/features/terminal/terminal_sessions_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Public API ───────────────────────────────────────────────────────────────

/// Shows a Spotlight-style search dialog as a floating overlay.
void showSpotlightSearch(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _SpotlightSearchDialog(ref: ref),
  );
}

// ── Category model ──────────────────────────────────────────────────────────

class _Category {
  const _Category({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String route;
}

List<_Category> _buildCategories(AppLocalizations l10n) => [
  _Category(
    label: l10n.projects,
    icon: Icons.folder_rounded,
    color: const Color(0xFF38BDF8),
    route: Routes.projects,
  ),
  _Category(
    label: l10n.features,
    icon: Icons.auto_awesome_rounded,
    color: const Color(0xFFA78BFA),
    route: Routes.projects,
  ),
  _Category(
    label: l10n.notes,
    icon: Icons.sticky_note_2_rounded,
    color: const Color(0xFFFBBF24),
    route: Routes.notes,
  ),
  _Category(
    label: l10n.docs,
    icon: Icons.menu_book_rounded,
    color: const Color(0xFF06B6D4),
    route: Routes.docs,
  ),
  _Category(
    label: l10n.skills,
    icon: Icons.bolt_rounded,
    color: const Color(0xFFF97316),
    route: Routes.skills,
  ),
  _Category(
    label: l10n.agents,
    icon: Icons.smart_toy_rounded,
    color: const Color(0xFF4ADE80),
    route: Routes.agents,
  ),
  _Category(
    label: l10n.workflows,
    icon: Icons.account_tree_rounded,
    color: const Color(0xFF818CF8),
    route: Routes.workflows,
  ),
  _Category(
    label: l10n.delegations,
    icon: Icons.sync_alt_rounded,
    color: const Color(0xFFA78BFA),
    route: Routes.delegations,
  ),
  // Terminal
  _Category(
    label: l10n.terminal,
    icon: Icons.terminal_rounded,
    color: const Color(0xFF10B981),
    route: Routes.terminal,
  ),
  // Health
  _Category(
    label: l10n.healthScore,
    icon: Icons.favorite_rounded,
    color: const Color(0xFFEF4444),
    route: Routes.healthScore,
  ),
  _Category(
    label: l10n.vitals,
    icon: Icons.monitor_heart_rounded,
    color: const Color(0xFFF43F5E),
    route: Routes.healthVitals,
  ),
  _Category(
    label: l10n.dailyFlow,
    icon: Icons.auto_graph_rounded,
    color: const Color(0xFF818CF8),
    route: Routes.healthFlow,
  ),
  _Category(
    label: l10n.hydration,
    icon: Icons.water_drop_rounded,
    color: const Color(0xFF38BDF8),
    route: Routes.healthHydration,
  ),
  _Category(
    label: l10n.caffeine,
    icon: Icons.coffee_rounded,
    color: const Color(0xFFF97316),
    route: Routes.healthCaffeine,
  ),
  _Category(
    label: l10n.nutrition,
    icon: Icons.restaurant_rounded,
    color: const Color(0xFF4ADE80),
    route: Routes.healthNutrition,
  ),
  _Category(
    label: l10n.pomodoro,
    icon: Icons.timer_rounded,
    color: const Color(0xFFF97316),
    route: Routes.healthPomodoro,
  ),
  _Category(
    label: l10n.shutdown,
    icon: Icons.nightlight_rounded,
    color: const Color(0xFF6366F1),
    route: Routes.healthShutdown,
  ),
  _Category(
    label: l10n.weight,
    icon: Icons.monitor_weight_rounded,
    color: const Color(0xFF14B8A6),
    route: Routes.healthWeight,
  ),
  _Category(
    label: l10n.sleep,
    icon: Icons.bedtime_rounded,
    color: const Color(0xFF8B5CF6),
    route: Routes.healthSleep,
  ),
];

// ── Search result model ──────────────────────────────────────────────────────

class _SearchResult {
  _SearchResult({
    required this.type,
    required this.title,
    this.subtitle,
    this.id,
  });

  final String type;
  final String title;
  final String? subtitle;
  final String? id;

  IconData get icon => switch (type) {
    'project' => Icons.folder_rounded,
    'feature' => Icons.auto_awesome_rounded,
    'note' => Icons.sticky_note_2_rounded,
    'agent' => Icons.smart_toy_rounded,
    'skill' => Icons.bolt_rounded,
    'workflow' => Icons.account_tree_rounded,
    'doc' => Icons.menu_book_rounded,
    'session' => Icons.chat_rounded,
    'terminal' => Icons.terminal_rounded,
    'delegation' => Icons.sync_alt_rounded,
    _ => Icons.search_rounded,
  };

  Color get iconColor => switch (type) {
    'project' => const Color(0xFF38BDF8),
    'feature' => const Color(0xFFA78BFA),
    'note' => const Color(0xFFFBBF24),
    'agent' => const Color(0xFF4ADE80),
    'skill' => const Color(0xFFF97316),
    'workflow' => const Color(0xFF818CF8),
    'doc' => const Color(0xFF06B6D4),
    'session' => const Color(0xFF22D3EE),
    'terminal' => const Color(0xFF10B981),
    'delegation' => const Color(0xFFA78BFA),
    _ => const Color(0xFF94A3B8),
  };

  String resolveTypeLabel(AppLocalizations l10n) => switch (type) {
    'project' => l10n.project,
    'feature' => l10n.feature,
    'note' => l10n.note,
    'agent' => l10n.agent,
    'skill' => l10n.skill,
    'workflow' => l10n.workflow,
    'doc' => l10n.doc,
    'session' => l10n.session,
    'terminal' => l10n.terminal,
    'delegation' => l10n.delegation,
    _ => type,
  };

  String? get route => switch (type) {
    'project' => '/projects/$id',
    'feature' => null,
    'note' => '/library/notes/$id',
    'agent' => '/library/agents/$id',
    'skill' => '/library/skills/$id',
    'workflow' => '/library/workflows/$id',
    'doc' => '/library/docs/$id',
    'session' => null,
    'terminal' => Routes.terminal,
    'delegation' => Routes.delegations,
    _ => null,
  };
}

// ── Dialog widget ────────────────────────────────────────────────────────────

class _SpotlightSearchDialog extends StatefulWidget {
  const _SpotlightSearchDialog({required this.ref});

  final WidgetRef ref;

  @override
  State<_SpotlightSearchDialog> createState() => _SpotlightSearchDialogState();
}

class _SpotlightSearchDialogState extends State<_SpotlightSearchDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<_SearchResult> _results = [];
  bool _loading = false;
  int _highlightIndex = 0;

  bool get _hasQuery => _controller.text.trim().isNotEmpty;

  List<_Category> _categories = [];

  /// Total number of navigable items (categories when no query, results when query).
  int get _itemCount => _hasQuery ? _results.length : _categories.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Search logic ───────────────────────────────────────────────────────

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query.trim());
      } else {
        setState(() {
          _results = [];
          _highlightIndex = 0;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final response = await widget.ref.read(apiClientProvider).search(query);
      final rawResults = response['results'];
      final items = <_SearchResult>[];

      // Match terminal sessions locally.
      final sessions = widget.ref.read(terminalSessionsProvider);
      final lowerQuery = query.toLowerCase();
      for (final session in sessions) {
        if (session.label.toLowerCase().contains(lowerQuery)) {
          items.add(
            _SearchResult(
              type: 'terminal',
              title: session.label,
              subtitle: l10n.terminalSessionSubtitle,
              id: session.id,
            ),
          );
        }
      }

      if (rawResults is List) {
        for (final entry in rawResults) {
          if (entry is Map<String, dynamic>) {
            items.add(
              _SearchResult(
                type: (entry['type'] as String?) ?? '',
                title:
                    (entry['title'] as String?) ??
                    (entry['name'] as String?) ??
                    '',
                subtitle:
                    (entry['subtitle'] as String?) ??
                    (entry['description'] as String?) ??
                    '',
                id: entry['id']?.toString(),
              ),
            );
          }
        }
      }
      if (mounted) {
        setState(() {
          _results = items;
          _highlightIndex = 0;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[SpotlightSearch] Search error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────

  void _navigateToResult(_SearchResult result) {
    final route = result.route;
    if (route == null) return;
    Navigator.of(context).pop();
    // When navigating to a terminal session, activate it.
    if (result.type == 'terminal' && result.id != null) {
      widget.ref.read(activeTerminalIdProvider.notifier).set(result.id);
    }
    context.go(route);
  }

  void _navigateToCategory(_Category category) {
    Navigator.of(context).pop();
    context.go(category.route);
  }

  void _selectHighlighted() {
    if (_hasQuery) {
      if (_results.isNotEmpty && _highlightIndex < _results.length) {
        _navigateToResult(_results[_highlightIndex]);
      }
    } else {
      if (_highlightIndex < _categories.length) {
        _navigateToCategory(_categories[_highlightIndex]);
      }
    }
  }

  // ── Keyboard handling ──────────────────────────────────────────────────

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_itemCount > 0) {
          _highlightIndex = (_highlightIndex + 1) % _itemCount;
        }
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_itemCount > 0) {
          _highlightIndex = (_highlightIndex - 1 + _itemCount) % _itemCount;
        }
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _selectHighlighted();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _categories = _buildCategories(l10n);
    final tokens = ThemeTokens.maybeOf(context);
    final bg = tokens?.bgAlt ?? Colors.grey.shade900;
    final fgBright = tokens?.fgBright ?? Colors.white;
    final fgMuted = tokens?.fgMuted ?? Colors.grey;
    final fgDim = tokens?.fgDim ?? Colors.grey.shade600;
    final accent = tokens?.accent ?? Colors.blueAccent;
    final borderFaint = tokens?.borderFaint ?? Colors.grey.shade800;
    final bgMain = tokens?.bg ?? Colors.black;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Focus(
              onKeyEvent: _handleKeyEvent,
              child: Container(
                width: 560,
                constraints: const BoxConstraints(maxHeight: 520),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderFaint, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Search field ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 20, color: fgMuted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              onChanged: _onQueryChanged,
                              style: TextStyle(color: fgBright, fontSize: 16),
                              cursorColor: accent,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(
                                  context,
                                ).searchEverything,
                                hintStyle: TextStyle(
                                  color: fgDim,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: bgMain.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'esc',
                              style: TextStyle(color: fgDim, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, color: borderFaint),

                    // ── Content area ─────────────────────────────
                    if (_loading)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accent,
                          ),
                        ),
                      )
                    else if (!_hasQuery)
                      // Show browsable category list
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _categories.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            indent: 56,
                            color: borderFaint.withValues(alpha: 0.5),
                          ),
                          itemBuilder: (_, i) {
                            final cat = _categories[i];
                            final highlighted = i == _highlightIndex;
                            return _CategoryTile(
                              category: cat,
                              highlighted: highlighted,
                              fgBright: fgBright,
                              accent: accent,
                              onTap: () => _navigateToCategory(cat),
                            );
                          },
                        ),
                      )
                    else if (_results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 36,
                              color: fgDim,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context).noResultsFound,
                              style: TextStyle(color: fgDim, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _results.length,
                          itemBuilder: (_, i) {
                            final r = _results[i];
                            final highlighted = i == _highlightIndex;
                            return _ResultTile(
                              result: r,
                              l10n: l10n,
                              highlighted: highlighted,
                              fgBright: fgBright,
                              fgMuted: fgMuted,
                              accent: accent,
                              bgMain: bgMain,
                              onTap: () => _navigateToResult(r),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category tile ────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.highlighted,
    required this.fgBright,
    required this.accent,
    required this.onTap,
  });

  final _Category category;
  final bool highlighted;
  final Color fgBright;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: highlighted
            ? accent.withValues(alpha: 0.10)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(category.icon, color: category.color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                category.label,
                style: TextStyle(
                  color: highlighted ? accent : fgBright,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              RtlUtils.dirIcon(
                context,
                ltr: Icons.chevron_right_rounded,
                rtl: Icons.chevron_left_rounded,
              ),
              size: 18,
              color: highlighted ? accent : fgBright.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Result tile ──────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.result,
    required this.l10n,
    required this.highlighted,
    required this.fgBright,
    required this.fgMuted,
    required this.accent,
    required this.bgMain,
    required this.onTap,
  });

  final _SearchResult result;
  final AppLocalizations l10n;
  final bool highlighted;
  final Color fgBright;
  final Color fgMuted;
  final Color accent;
  final Color bgMain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: highlighted
            ? accent.withValues(alpha: 0.10)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: result.iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(result.icon, color: result.iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.title,
                    style: TextStyle(
                      color: highlighted ? accent : fgBright,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.subtitle != null &&
                      result.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      result.subtitle!,
                      style: TextStyle(color: fgMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: bgMain.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                result.resolveTypeLabel(l10n),
                style: TextStyle(
                  color: result.iconColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
