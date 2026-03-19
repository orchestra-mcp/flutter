import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';

/// Data model for a single onboarding step.
@immutable
class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentOverride,
  });

  /// Primary headline shown in large text.
  final String title;

  /// Supporting description beneath the headline.
  final String subtitle;

  /// Icon rendered inside the illustration container.
  final IconData icon;

  /// Per-page accent tint applied to the illustration background.
  /// Pass [null] to fall back to [OrchestraColorTokens.accentSurface].
  final Color? accentOverride;
}

/// A single page inside the onboarding [PageView].
///
/// Displays a full-screen layout with:
/// - a centred illustration placeholder (coloured container + icon)
/// - a title
/// - a subtitle
///
/// All colours come from [ThemeTokens.of(context)]; no hex values are
/// hard-coded here.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.data,
  });

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _Illustration(data: data, tokens: tokens),
          const SizedBox(height: 48),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              color: tokens.fgBright,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: tokens.fgMuted,
              height: 1.6,
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

/// Illustration placeholder — a rounded rectangle with a centred icon.
///
/// The background tint uses [OnboardingPageData.accentOverride] when provided,
/// falling back to the standard accent surface colour from [tokens].
class _Illustration extends StatelessWidget {
  const _Illustration({required this.data, required this.tokens});

  final OnboardingPageData data;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final tint = data.accentOverride ?? tokens.accentSurface;

    return Semantics(
      label: data.title,
      excludeSemantics: true,
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: tint.withValues(alpha: 0.18),
          border: Border.all(
            color: tint.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            data.icon,
            size: 80,
            color: tint.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}
