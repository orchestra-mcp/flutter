import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/update/update_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// About settings tab -- app info, update check, report issue, license viewer.
class AboutSettingsTab extends ConsumerStatefulWidget {
  const AboutSettingsTab({super.key});

  @override
  ConsumerState<AboutSettingsTab> createState() => _AboutSettingsTabState();
}

class _AboutSettingsTabState extends ConsumerState<AboutSettingsTab> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _packageInfo = info);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final updateState = ref.watch(updateProvider);

    final appVersion = _packageInfo?.version ?? '...';
    final buildNumber = _packageInfo?.buildNumber ?? '...';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── App info ──────────────────────────────────────────────────────
        _sectionHeader(tokens, l10n.aboutSettingsAppInfo),
        const SizedBox(height: 12),
        _buildInfoCard(tokens, l10n, appVersion, buildNumber),

        const SizedBox(height: 16),

        // ── Update check ────────────────────────────────────────────────
        _buildUpdateSection(tokens, l10n, updateState),

        const SizedBox(height: 28),
        Divider(color: tokens.border.withValues(alpha: 0.4)),
        const SizedBox(height: 20),

        // ── Support ───────────────────────────────────────────────────────
        _sectionHeader(tokens, l10n.aboutSettingsSupport),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/settings/report-issue'),
            icon: const Icon(Icons.bug_report_rounded, size: 18),
            label: Text(AppLocalizations.of(context).reportIssue),
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Issue history ─────────────────────────────────────────────────
        _sectionHeader(tokens, l10n.aboutSettingsIssueHistory),
        const SizedBox(height: 12),
        _buildIssueHistory(tokens, l10n),

        const SizedBox(height: 28),
        Divider(color: tokens.border.withValues(alpha: 0.4)),
        const SizedBox(height: 20),

        // ── Legal ─────────────────────────────────────────────────────────
        _sectionHeader(tokens, l10n.aboutSettingsLegal),
        const SizedBox(height: 12),
        _buildLegalTile(
          tokens: tokens,
          icon: Icons.description_rounded,
          label: l10n.aboutSettingsOpenSourceLicenses,
          onTap: () => showLicensePage(
            context: context,
            applicationName: l10n.aboutSettingsOrchestra,
            applicationVersion: '$appVersion+$buildNumber',
          ),
        ),
        const SizedBox(height: 8),
        _buildLegalTile(
          tokens: tokens,
          icon: Icons.privacy_tip_rounded,
          label: l10n.aboutSettingsPrivacyPolicy,
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _buildLegalTile(
          tokens: tokens,
          icon: Icons.gavel_rounded,
          label: l10n.aboutSettingsTermsOfService,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    OrchestraColorTokens tokens,
    AppLocalizations l10n,
    String appVersion,
    String buildNumber,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/images/logo.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.aboutSettingsOrchestra,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tokens.fgBright,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.aboutSettingsAiAgenticFirstIde,
            style: TextStyle(fontSize: 13, color: tokens.fgMuted),
          ),
          const SizedBox(height: 16),
          Divider(color: tokens.border.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          _infoRow(tokens, l10n.aboutSettingsVersion, appVersion),
          const SizedBox(height: 8),
          _infoRow(tokens, l10n.aboutSettingsBuild, buildNumber),
        ],
      ),
    );
  }

  Widget _buildUpdateSection(
    OrchestraColorTokens tokens,
    AppLocalizations l10n,
    UpdateState updateState,
  ) {
    final notifier = ref.read(updateProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _updateIcon(updateState.status),
                size: 18,
                color: _updateColor(updateState.status),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _updateLabel(l10n, updateState),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.fgBright,
                  ),
                ),
              ),
              if (updateState.status == UpdateStatus.available)
                SizedBox(
                  height: 30,
                  child: FilledButton(
                    onPressed: () => notifier.install(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context).update),
                  ),
                ),
              if (updateState.status == UpdateStatus.upToDate ||
                  updateState.status == UpdateStatus.idle ||
                  updateState.status == UpdateStatus.error)
                SizedBox(
                  height: 30,
                  child: OutlinedButton(
                    onPressed: () => notifier.checkForUpdate(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tokens.fgMuted,
                      side: BorderSide(color: tokens.border),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context).check),
                  ),
                ),
            ],
          ),
          if (updateState.status == UpdateStatus.downloading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: updateState.downloadProgress,
                minHeight: 4,
                backgroundColor: tokens.border,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
              ),
            ),
          ],
          if (updateState.status == UpdateStatus.error &&
              updateState.error != null) ...[
            const SizedBox(height: 8),
            Text(
              updateState.error!,
              style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
            ),
          ],
        ],
      ),
    );
  }

  String _updateLabel(AppLocalizations l10n, UpdateState state) {
    switch (state.status) {
      case UpdateStatus.idle:
      case UpdateStatus.upToDate:
        return l10n.aboutSettingsUpToDate;
      case UpdateStatus.checking:
        return l10n.aboutSettingsCheckingForUpdates;
      case UpdateStatus.available:
        return l10n.aboutSettingsVersionAvailable(
          state.info?.latestVersion ?? '',
        );
      case UpdateStatus.downloading:
        return l10n.aboutSettingsDownloadingVersion(
          state.info?.latestVersion ?? '',
        );
      case UpdateStatus.readyToInstall:
        return l10n.aboutSettingsReadyToInstall(
          state.info?.latestVersion ?? '',
        );
      case UpdateStatus.error:
        return l10n.aboutSettingsUpdateCheckFailed;
    }
  }

  IconData _updateIcon(UpdateStatus status) {
    switch (status) {
      case UpdateStatus.upToDate:
        return Icons.check_circle_outline_rounded;
      case UpdateStatus.checking:
        return Icons.sync_rounded;
      case UpdateStatus.available:
        return Icons.system_update_rounded;
      case UpdateStatus.downloading:
        return Icons.downloading_rounded;
      case UpdateStatus.readyToInstall:
        return Icons.restart_alt_rounded;
      case UpdateStatus.error:
        return Icons.error_outline_rounded;
      case UpdateStatus.idle:
        return Icons.info_outline_rounded;
    }
  }

  Color _updateColor(UpdateStatus status) {
    switch (status) {
      case UpdateStatus.upToDate:
        return const Color(0xFF22C55E);
      case UpdateStatus.available:
      case UpdateStatus.downloading:
      case UpdateStatus.readyToInstall:
        return const Color(0xFF8B5CF6);
      case UpdateStatus.error:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Widget _infoRow(OrchestraColorTokens tokens, String label, String value) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: tokens.fgDim)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: tokens.fgMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildIssueHistory(
    OrchestraColorTokens tokens,
    AppLocalizations l10n,
  ) {
    const issues = [
      _IssueEntry(
        title: 'Theme not persisting on restart',
        category: 'Bug',
        severity: 'Medium',
        date: '2026-03-14',
        status: 'Open',
      ),
      _IssueEntry(
        title: 'Keyboard shortcut conflict',
        category: 'Bug',
        severity: 'Low',
        date: '2026-03-12',
        status: 'Resolved',
      ),
    ];

    if (issues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.bgAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.border),
        ),
        child: Text(
          l10n.aboutSettingsNoIssuesReported,
          style: TextStyle(fontSize: 13, color: tokens.fgDim),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < issues.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 14,
                color: tokens.border.withValues(alpha: 0.4),
              ),
            _IssueRow(issue: issues[i], tokens: tokens),
          ],
        ],
      ),
    );
  }

  Widget _buildLegalTile({
    required OrchestraColorTokens tokens,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: tokens.bgAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: tokens.fgMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14, color: tokens.fgBright),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: tokens.fgDim),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(OrchestraColorTokens tokens, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: tokens.fgBright,
    ),
  );
}

// ── Issue entry model ───────────────────────────────────────────────────────

class _IssueEntry {
  const _IssueEntry({
    required this.title,
    required this.category,
    required this.severity,
    required this.date,
    required this.status,
  });

  final String title;
  final String category;
  final String severity;
  final String date;
  final String status;
}

// ── Issue row widget ────────────────────────────────────────────────────────

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue, required this.tokens});

  final _IssueEntry issue;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isOpen = issue.status == 'Open';
    final statusColor = isOpen
        ? const Color(0xFFF59E0B)
        : const Color(0xFF22C55E);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.fgBright,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${issue.category} / ${issue.severity} / ${issue.date}',
                  style: TextStyle(fontSize: 11, color: tokens.fgDim),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              issue.status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
