import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Scaffold wrapper for individual health sub-pages.
///
/// Provides a back button, title, and renders the [child] widget
/// (one of the existing health tab widgets).
///
/// Pass [titleResolver] to get the localized title from [AppLocalizations].
class HealthPageWrapper extends StatelessWidget {
  const HealthPageWrapper({
    super.key,
    required this.titleResolver,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String Function(AppLocalizations) titleResolver;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);

    return ColoredBox(
      color: tokens.bg,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        context.go('/health');
                      }
                    },
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: tokens.accent,
                      size: 28,
                    ),
                  ),
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    titleResolver(l10n),
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
