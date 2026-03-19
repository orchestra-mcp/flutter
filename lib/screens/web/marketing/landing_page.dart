import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Public landing page — hero, features overview, CTA.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      body: Center(child: Text(l10n.landingComingSoon)),
    );
  }
}

/// Download page — platform asset links.
class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});
  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      body: Center(child: Text(l10n.downloadComingSoon)),
    );
  }
}

/// Pricing page.
class PricingPage extends StatelessWidget {
  const PricingPage({super.key});
  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      body: Center(child: Text(l10n.pricingComingSoon)),
    );
  }
}

/// About page.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      body: Center(child: Text(l10n.aboutComingSoon)),
    );
  }
}

/// Status page.
class StatusPage extends StatelessWidget {
  const StatusPage({super.key});
  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      body: Center(child: Text(l10n.statusComingSoon)),
    );
  }
}
