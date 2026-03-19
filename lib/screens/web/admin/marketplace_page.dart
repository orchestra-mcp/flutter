import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ── Marketplace data provider ────────────────────────────────────────────────

final _marketplaceProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final marketplace = await api.getAdminSetting('marketplace');
  final plugins = await api.getAdminSetting('plugins');
  return {'marketplace': marketplace, 'plugins': plugins};
});

/// User-shared items from PowerSync (skills/agents/workflows marked as shared).
final _sharedSkillsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(powersyncDatabaseProvider);
  return db.getAll(
    "SELECT * FROM skills WHERE scope = 'public' ORDER BY updated_at DESC",
  );
});

final _sharedAgentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(powersyncDatabaseProvider);
  return db.getAll(
    "SELECT * FROM agents WHERE scope = 'public' ORDER BY updated_at DESC",
  );
});

final _sharedWorkflowsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(powersyncDatabaseProvider);
  return db.getAll(
    "SELECT * FROM workflows ORDER BY updated_at DESC",
  );
});

// ── Marketplace page ────────────────────────────────────────────────────────

/// Full marketplace page with 5 tabs: Plugins, Packs, Skills, Agents, Workflows.
///
/// - Plugins & Packs: fetched from admin settings API, show README via GitHub.
/// - Skills, Agents, Workflows: user-shared items from PowerSync.
/// - All items support deep link install: `orchestra://install/<type>/<repo>`.
class MarketplacePage extends ConsumerStatefulWidget {
  const MarketplacePage({super.key});

  @override
  ConsumerState<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends ConsumerState<MarketplacePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);

    return ColoredBox(
      color: tokens.bg,
      child: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.search,
                hintStyle: TextStyle(color: tokens.fgDim),
                prefixIcon: Icon(Icons.search, color: tokens.fgMuted),
                filled: true,
                fillColor: tokens.bgAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: TextStyle(color: tokens.fgBright, fontSize: 14),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),

          // ── Tab bar ────────────────────────────────────────────────
          TabBar(
            controller: _tabController,
            labelColor: tokens.accent,
            unselectedLabelColor: tokens.fgMuted,
            indicatorColor: tokens.accent,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Plugins'),
              Tab(text: 'Packs'),
              Tab(text: 'Skills'),
              Tab(text: 'Agents'),
              Tab(text: 'Workflows'),
            ],
          ),

          // ── Tab content ────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PluginsTab(search: _search),
                _PacksTab(search: _search),
                _SharedItemsTab(
                    provider: _sharedSkillsProvider,
                    type: 'skill',
                    search: _search),
                _SharedItemsTab(
                    provider: _sharedAgentsProvider,
                    type: 'agent',
                    search: _search),
                _SharedItemsTab(
                    provider: _sharedWorkflowsProvider,
                    type: 'workflow',
                    search: _search),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plugins tab ──────────────────────────────────────────────────────────────

class _PluginsTab extends ConsumerWidget {
  const _PluginsTab({required this.search});
  final String search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final asyncData = ref.watch(_marketplaceProvider);

    return asyncData.when(
      loading: () => Center(child: CircularProgressIndicator(color: tokens.accent)),
      error: (e, _) => Center(child: Text('$e', style: TextStyle(color: tokens.fgMuted))),
      data: (data) {
        final pluginsData = data['plugins'] as Map<String, dynamic>? ?? {};
        final core = (pluginsData['core_plugins'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final optional = (pluginsData['optional_plugins'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final all = [...core, ...optional];
        final filtered = search.isEmpty
            ? all
            : all.where((p) {
                final name = (p['name'] ?? '').toString().toLowerCase();
                final desc = (p['desc'] ?? '').toString().toLowerCase();
                return name.contains(search) || desc.contains(search);
              }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          itemBuilder: (context, i) => _PluginCard(
            plugin: filtered[i],
            isCore: i < core.length && search.isEmpty,
          ),
        );
      },
    );
  }
}

class _PluginCard extends StatelessWidget {
  const _PluginCard({required this.plugin, this.isCore = false});
  final Map<String, dynamic> plugin;
  final bool isCore;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final name = plugin['name']?.toString() ?? '';
    final desc = plugin['desc']?.toString() ?? '';
    final tools = plugin['tools'] as int? ?? 0;
    final lang = plugin['lang']?.toString() ?? 'Go';
    final repo = plugin['repo']?.toString() ?? '';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      onTap: repo.isNotEmpty
          ? () => _showDetailSheet(context, tokens, name, desc, repo, 'plugin')
          : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isCore ? tokens.accent : tokens.fgMuted).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCore ? Icons.extension_rounded : Icons.widgets_outlined,
              color: isCore ? tokens.accent : tokens.fgMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: TextStyle(
                            color: tokens.fgBright,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    if (isCore)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: tokens.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('core',
                            style: TextStyle(color: tokens.accent, fontSize: 9)),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: tokens.fgDim.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(lang,
                          style: TextStyle(color: tokens.fgDim, fontSize: 9)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tokens.fgMuted, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text('$tools',
                  style: TextStyle(
                      color: tokens.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              Text('tools',
                  style: TextStyle(color: tokens.fgDim, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Packs tab ────────────────────────────────────────────────────────────────

class _PacksTab extends ConsumerWidget {
  const _PacksTab({required this.search});
  final String search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final asyncData = ref.watch(_marketplaceProvider);

    return asyncData.when(
      loading: () => Center(child: CircularProgressIndicator(color: tokens.accent)),
      error: (e, _) => Center(child: Text('$e', style: TextStyle(color: tokens.fgMuted))),
      data: (data) {
        final mkt = data['marketplace'] as Map<String, dynamic>? ?? {};
        final packs = (mkt['packs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final filtered = search.isEmpty
            ? packs
            : packs.where((p) {
                final name = (p['display_name'] ?? p['name'] ?? '').toString().toLowerCase();
                final desc = (p['desc'] ?? '').toString().toLowerCase();
                final tags = (p['tags'] as List?)?.join(' ').toLowerCase() ?? '';
                return name.contains(search) || desc.contains(search) || tags.contains(search);
              }).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : 2,
            childAspectRatio: isMobile ? 2.8 : 2.4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, i) => _PackCard(pack: filtered[i]),
        );
      },
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({required this.pack});
  final Map<String, dynamic> pack;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final displayName = pack['display_name']?.toString() ?? pack['name']?.toString() ?? '';
    final desc = pack['desc']?.toString() ?? '';
    final color = _parseColor(pack['color']?.toString() ?? '#888888');
    final skills = pack['skills'] as int? ?? 0;
    final agents = pack['agents'] as int? ?? 0;
    final hooks = pack['hooks'] as int? ?? 0;
    final repo = pack['repo']?.toString() ?? '';
    final tags = (pack['tags'] as List?)?.cast<String>() ?? [];

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: repo.isNotEmpty
          ? () => _showDetailSheet(context, tokens, displayName, desc, repo, 'pack')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory_2_rounded, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(displayName,
                    style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: tokens.fgMuted, fontSize: 11)),
          const Spacer(),
          Row(
            children: [
              _StatChip('$skills skills', color, tokens),
              const SizedBox(width: 6),
              _StatChip('$agents agents', color, tokens),
              const SizedBox(width: 6),
              _StatChip('$hooks hooks', color, tokens),
              const Spacer(),
              if (tags.isNotEmpty)
                Text(tags.take(2).join(', '),
                    style: TextStyle(color: tokens.fgDim, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.label, this.color, this.tokens);
  final String label;
  final Color color;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 9)),
    );
  }
}

// ── Shared items tab (Skills / Agents / Workflows) ───────────────────────────

class _SharedItemsTab extends ConsumerWidget {
  const _SharedItemsTab({
    required this.provider,
    required this.type,
    required this.search,
  });

  final FutureProvider<List<Map<String, dynamic>>> provider;
  final String type;
  final String search;

  IconData get _icon => switch (type) {
        'skill' => Icons.bolt_rounded,
        'agent' => Icons.smart_toy_rounded,
        'workflow' => Icons.account_tree_rounded,
        _ => Icons.extension_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final asyncData = ref.watch(provider);

    return asyncData.when(
      loading: () => Center(child: CircularProgressIndicator(color: tokens.accent)),
      error: (e, _) => Center(child: Text('$e', style: TextStyle(color: tokens.fgMuted))),
      data: (items) {
        final filtered = search.isEmpty
            ? items
            : items.where((item) {
                final name = (item['name'] ?? '').toString().toLowerCase();
                final desc = (item['description'] ?? '').toString().toLowerCase();
                return name.contains(search) || desc.contains(search);
              }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon, size: 48, color: tokens.fgDim),
                const SizedBox(height: 12),
                Text('No shared ${type}s yet',
                    style: TextStyle(color: tokens.fgMuted, fontSize: 14)),
                const SizedBox(height: 6),
                Text('Mark your ${type}s as "public" to share them here',
                    style: TextStyle(color: tokens.fgDim, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final item = filtered[i];
            final name = item['name']?.toString() ?? '';
            final desc = item['description']?.toString() ?? '';
            final slug = item['slug']?.toString() ?? '';
            final version = item['version']?.toString() ?? '';

            return GlassCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              onTap: () => _showSharedItemSheet(context, tokens, item, type),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tokens.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_icon, color: tokens.accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                                color: tokens.fgBright,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        if (desc.isNotEmpty)
                          Text(desc,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: tokens.fgMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  if (slug.isNotEmpty)
                    Text(slug,
                        style: TextStyle(color: tokens.fgDim, fontSize: 10)),
                  if (version.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text('v$version',
                        style: TextStyle(color: tokens.fgDim, fontSize: 10)),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Detail sheet (plugin/pack with README + deep link install) ────────────────

void _showDetailSheet(
  BuildContext context,
  OrchestraColorTokens tokens,
  String name,
  String desc,
  String repo,
  String type,
) {
  final installCmd = 'orchestra ${type == 'plugin' ? 'install' : 'pack install'} $repo';
  final deepLink = 'orchestra://install/$type/$repo';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: tokens.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: tokens.fgDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Text(name,
              style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(desc,
              style: TextStyle(color: tokens.fgMuted, fontSize: 13)),
          const SizedBox(height: 16),
          // Repo link
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.code_rounded, color: tokens.fgMuted, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('github.com/$repo',
                      style: TextStyle(color: tokens.fgBright, fontSize: 12,
                          fontFamily: 'monospace')),
                ),
                IconButton(
                  icon: Icon(Icons.copy_rounded, color: tokens.accent, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: 'github.com/$repo'));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Copied')),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Install command
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal_rounded, color: tokens.fgMuted, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(installCmd,
                      style: TextStyle(color: tokens.accent, fontSize: 12,
                          fontFamily: 'monospace')),
                ),
                IconButton(
                  icon: Icon(Icons.copy_rounded, color: tokens.accent, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: installCmd));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Install command copied')),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Install button (deep link)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Copy deep link for now — native URL scheme handling
                // will be added when the desktop app registers orchestra://.
                Clipboard.setData(ClipboardData(text: deepLink));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Deep link copied: $deepLink')),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text('Install $name'),
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // README placeholder
          Text('README.md',
              style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Loading README from github.com/$repo...\n\n'
              'README content will be fetched from the GitHub repository.',
              style: TextStyle(color: tokens.fgMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showSharedItemSheet(
  BuildContext context,
  OrchestraColorTokens tokens,
  Map<String, dynamic> item,
  String type,
) {
  final name = item['name']?.toString() ?? '';
  final desc = item['description']?.toString() ?? '';
  final content = item['content']?.toString() ?? '';
  final slug = item['slug']?.toString() ?? '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: tokens.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      expand: false,
      builder: (ctx, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: tokens.fgDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(name,
              style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          if (slug.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(slug,
                style: TextStyle(color: tokens.fgDim, fontSize: 12,
                    fontFamily: 'monospace')),
          ],
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(desc,
                style: TextStyle(color: tokens.fgMuted, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          // Content preview
          if (content.isNotEmpty) ...[
            Text('Content',
                style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(content,
                  style: TextStyle(
                      color: tokens.fgMuted,
                      fontSize: 12,
                      fontFamily: 'monospace')),
            ),
          ],
          const SizedBox(height: 16),
          // Deep link install
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final deepLink = 'orchestra://install/$type/$slug';
                Clipboard.setData(ClipboardData(text: deepLink));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Deep link copied: $deepLink')),
                );
              },
              icon: const Icon(Icons.share_rounded, size: 18),
              label: Text('Share $type'),
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
  return const Color(0xFF888888);
}
