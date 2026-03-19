import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_button.dart';
import 'package:orchestra/widgets/glass_card.dart';

/// Public landing page — hero, feature grid, pricing CTA, footer.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 900 ? 3 : (width >= 600 ? 2 : 1);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _HeroSection(tokens: tokens)),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate(_featureCards(tokens)),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _Footer(tokens: tokens)),
        ],
      ),
    );
  }

  List<Widget> _featureCards(OrchestraColorTokens tokens) => const [
    _FeatureCard(
      icon: Icons.build_outlined,
      title: 'MCP Tools',
      desc: '290+ tools via Model Context Protocol',
    ),
    _FeatureCard(
      icon: Icons.favorite_outline,
      title: 'Health Tracking',
      desc: 'HealthKit & Health Connect integration',
    ),
    _FeatureCard(
      icon: Icons.devices,
      title: 'Multi-Platform',
      desc: 'macOS, Windows, Linux, iOS, Android, Web',
    ),
    _FeatureCard(
      icon: Icons.bolt_outlined,
      title: 'Smart Actions',
      desc: 'AI-powered project automation',
    ),
    _FeatureCard(
      icon: Icons.sync,
      title: 'Sync Engine',
      desc: 'Real-time cross-device synchronisation',
    ),
    _FeatureCard(
      icon: Icons.code,
      title: 'Open Source',
      desc: 'MIT-licensed and community-driven',
    ),
  ];
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Text(
            l10n.orchestraAi,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: tokens.fgBright,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.aiDescription,
            style: TextStyle(fontSize: 18, color: tokens.fgMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            children: [
              GlassButton(
                label: l10n.getStartedFree,
                onPressed: () => context.go('/register'),
              ),
              OutlinedButton(onPressed: () {}, child: Text(l10n.viewDemo)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.desc,
  });
  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tokens.accent, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: tokens.fgBright,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: tokens.fgMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Wrap(
      spacing: 24,
      children: ['/docs', '/blog', '/pricing', '/about']
          .map(
            (r) => TextButton(
              onPressed: () => context.go(r),
              child: Text(r, style: TextStyle(color: tokens.fgMuted)),
            ),
          )
          .toList(),
    ),
  );
}
