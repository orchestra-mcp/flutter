import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Data provider ────────────────────────────────────────────────────────────

final _teamsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.listAdminTeams();
  final raw = result['teams'];
  if (raw is! List) return [];
  return raw.cast<Map<String, dynamic>>();
});

// ── Search state ────────────────────────────────────────────────────────────

class _TeamSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final _teamSearchProvider =
    NotifierProvider<_TeamSearchNotifier, String>(_TeamSearchNotifier.new);

// ── Dialogs ─────────────────────────────────────────────────────────────────

void _showCreateTeamDialog(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final tokens = ThemeTokens.of(context);

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: tokens.bgAlt,
      titleTextStyle: TextStyle(
        color: tokens.fgBright,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      title: Text(AppLocalizations.of(ctx).createTeam),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(ctx).name,
                labelStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                filled: true,
                fillColor: tokens.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.accent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(ctx).descriptionLabel,
                labelStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                filled: true,
                fillColor: tokens.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.accent),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(ctx).cancel, style: TextStyle(color: tokens.fgDim)),
        ),
        FilledButton(
          onPressed: () async {
            final api = ref.read(apiClientProvider);
            await api.createAdminTeam({
              'name': nameCtrl.text,
              'description': descCtrl.text,
            });
            ref.invalidate(_teamsProvider);
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: tokens.accent,
            foregroundColor: tokens.bg,
          ),
          child: Text(AppLocalizations.of(ctx).create),
        ),
      ],
    ),
  );
}

void _showEditTeamDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> team,
) {
  final nameCtrl = TextEditingController(text: team['name'] as String? ?? '');
  final descCtrl =
      TextEditingController(text: team['description'] as String? ?? '');
  final tokens = ThemeTokens.of(context);

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: tokens.bgAlt,
      titleTextStyle: TextStyle(
        color: tokens.fgBright,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      title: Text(AppLocalizations.of(ctx).editTeam),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(ctx).name,
                labelStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                filled: true,
                fillColor: tokens.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.accent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(ctx).descriptionLabel,
                labelStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                filled: true,
                fillColor: tokens.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.accent),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(ctx).cancel, style: TextStyle(color: tokens.fgDim)),
        ),
        FilledButton(
          onPressed: () async {
            final api = ref.read(apiClientProvider);
            await api.updateAdminTeam(
              (team['id'] as num).toInt(),
              {
                'name': nameCtrl.text,
                'description': descCtrl.text,
              },
            );
            ref.invalidate(_teamsProvider);
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: tokens.accent,
            foregroundColor: tokens.bg,
          ),
          child: Text(AppLocalizations.of(ctx).save),
        ),
      ],
    ),
  );
}

void _showDeleteTeamDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> team,
) {
  final tokens = ThemeTokens.of(context);
  final name = team['name'] as String? ?? 'this team';

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: tokens.bgAlt,
      titleTextStyle: TextStyle(
        color: tokens.fgBright,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      title: Text(AppLocalizations.of(ctx).deleteTeamConfirm),
      content: Text(
        AppLocalizations.of(ctx).areYouSureDelete(name),
        style: TextStyle(color: tokens.fgMuted, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(ctx).cancel, style: TextStyle(color: tokens.fgDim)),
        ),
        FilledButton(
          onPressed: () async {
            final api = ref.read(apiClientProvider);
            await api.deleteAdminTeam((team['id'] as num).toInt());
            ref.invalidate(_teamsProvider);
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          child: Text(AppLocalizations.of(ctx).delete),
        ),
      ],
    ),
  );
}

// ── Teams page ──────────────────────────────────────────────────────────────

/// Admin teams management page.
///
/// Displays a searchable list of teams with name, member count, and plan.
/// Includes a "Create Team" button.
class TeamsPage extends ConsumerWidget {
  const TeamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final teamsAsync = ref.watch(_teamsProvider);

    return ColoredBox(
      color: tokens.bg,
      child: teamsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: tokens.fgDim),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).failedToLoadTeams,
              style: TextStyle(color: tokens.fgBright, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '$e',
              style: TextStyle(color: tokens.fgDim, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(_teamsProvider),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
      data: (teams) => _TeamsContent(teams: teams),
      ),
    );
  }
}

class _TeamsContent extends ConsumerWidget {
  const _TeamsContent({required this.teams});

  final List<Map<String, dynamic>> teams;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final query = ref.watch(_teamSearchProvider).toLowerCase();

    final filtered = teams.where((t) {
      if (query.isEmpty) return true;
      final name = (t['name'] as String? ?? '').toLowerCase();
      final slug = (t['slug'] as String? ?? '').toLowerCase();
      return name.contains(query) || slug.contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                AppLocalizations.of(context).teams,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showCreateTeamDialog(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: Text(AppLocalizations.of(context).createTeam),
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.accent,
                  foregroundColor: tokens.bg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).nTeamsTotal(teams.length),
            style: TextStyle(color: tokens.fgDim, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // ── Search ────────────────────────────────────────────────────
          SizedBox(
            width: 320,
            child: TextField(
              onChanged: (v) =>
                  ref.read(_teamSearchProvider.notifier).update(v),
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchTeams,
                hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 18, color: tokens.fgDim),
                filled: true,
                fillColor: tokens.bgAlt,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.accent),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Team list ─────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _TeamTile(tokens: tokens, team: filtered[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Team tile ───────────────────────────────────────────────────────────────

class _TeamTile extends ConsumerWidget {
  const _TeamTile({required this.tokens, required this.team});

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = team['name'] as String? ?? '';
    final memberCount = team['member_count'] as int? ?? 0;
    final plan = team['plan'] as String? ?? '';
    final avatarUrl = team['avatar_url'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: tokens.accent.withValues(alpha: 0.15),
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Icon(Icons.groups_outlined, size: 18, color: tokens.accent)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context).nMembers(memberCount),
                  style: TextStyle(color: tokens.fgDim, fontSize: 12),
                ),
              ],
            ),
          ),
          if (plan.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tokens.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                plan,
                style: TextStyle(
                  color: tokens.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(width: 12),
          IconButton(
            icon:
                Icon(Icons.edit_outlined, size: 16, color: tokens.fgMuted),
            onPressed: () => _showEditTeamDialog(context, ref, team),
            visualDensity: VisualDensity.compact,
            tooltip: AppLocalizations.of(context).editTeam,
          ),
          IconButton(
            icon:
                Icon(Icons.delete_outlined, size: 16, color: tokens.fgDim),
            onPressed: () => _showDeleteTeamDialog(context, ref, team),
            visualDensity: VisualDensity.compact,
            tooltip: AppLocalizations.of(context).deleteTeam,
          ),
        ],
      ),
    );
  }
}
