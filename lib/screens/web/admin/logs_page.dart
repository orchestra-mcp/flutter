import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Logs page ────────────────────────────────────────────────────────────────

/// Admin logs page.
///
/// No audit-log / system-log API endpoints exist yet. Shows a branded
/// placeholder with the same visual style as other admin pages.
class LogsPage extends ConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(apiClientProvider);
    final tokens = ThemeTokens.of(context);

    return ColoredBox(
      color: tokens.bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.article_outlined,
                  size: 36,
                  color: tokens.accent,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).logsTitle,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).systemLogsDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tokens.fgMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: tokens.bgAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.border),
                ),
                child: Text(
                  AppLocalizations.of(context).comingSoon,
                  style: TextStyle(
                    color: tokens.fgDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
