import 'package:flutter/material.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ─── Pricing tier data ────────────────────────────────────────────────────────

class _Tier {
  const _Tier({
    required this.name,
    required this.price,
    required this.description,
    required this.features,
    required this.ctaLabel,
    this.highlighted = false,
  });

  final String name;
  final String price;
  final String description;
  final List<String> features;
  final String ctaLabel;
  final bool highlighted;
}

const _tiers = [
  _Tier(
    name: 'Free',
    price: '\$0',
    description: 'For individuals getting started.',
    features: [
      'Up to 3 projects',
      '5 AI agent sessions / mo',
      'Basic health tracking',
      'Community support',
    ],
    ctaLabel: 'Get started free',
  ),
  _Tier(
    name: 'Pro',
    price: '\$12/mo',
    description: 'For professional developers.',
    features: [
      'Unlimited projects',
      '100 AI agent sessions / mo',
      'Full health & sleep tracking',
      'Priority support',
      'Sync across all devices',
    ],
    ctaLabel: 'Start free trial',
    highlighted: true,
  ),
  _Tier(
    name: 'Team',
    price: '\$49/mo',
    description: 'For teams that ship together.',
    features: [
      'Everything in Pro',
      'Unlimited team members',
      'Shared workspaces',
      'Team analytics',
      'SSO / SAML',
      'Dedicated support',
    ],
    ctaLabel: 'Contact sales',
  ),
];

// ─── Pricing page ─────────────────────────────────────────────────────────────

/// Public pricing page with Free, Pro, and Team tiers.
class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          children: [
            Builder(builder: (context) => Text(
              AppLocalizations.of(context).simplePricing,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            )),
            const SizedBox(height: 12),
            Builder(builder: (context) => Text(
              AppLocalizations.of(context).startFreeUpgrade,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9090A8), fontSize: 18),
            )),
            const SizedBox(height: 48),
            LayoutBuilder(builder: (context, constraints) {
              final useRow = constraints.maxWidth >= 800;
              final cards = _tiers.map((t) => _TierCard(tier: t)).toList();
              return useRow
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int i = 0; i < cards.length; i++) ...[
                            if (i > 0) const SizedBox(width: 16),
                            Expanded(child: cards[i]),
                          ],
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(height: 16),
                          cards[i],
                        ],
                      ],
                    );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Tier card ────────────────────────────────────────────────────────────────

class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier});
  final _Tier tier;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF7C6FFF);
    final border =
        tier.highlighted ? accent : const Color(0xFF2E2E42);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tier.highlighted
            ? accent.withValues(alpha: 0.08)
            : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: tier.highlighted ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tier.highlighted)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Builder(builder: (context) => Text(AppLocalizations.of(context).mostPopular,
                  style: const TextStyle(color: Colors.white, fontSize: 11))),
            ),
          Text(tier.name,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(tier.price,
              style: TextStyle(
                  color: tier.highlighted ? accent : Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(tier.description,
              style: const TextStyle(color: Color(0xFF9090A8), fontSize: 13)),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFF2E2E42)),
          const SizedBox(height: 16),
          for (final feature in tier.features) ...[
            Row(children: [
              Icon(Icons.check_circle_outline, size: 16, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(feature,
                    style: const TextStyle(color: Color(0xFFD0D0E0), fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 10),
          ],
          const Spacer(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: tier.highlighted
                ? FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    child: Text(tier.ctaLabel),
                  )
                : OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: border),
                    ),
                    child: Text(tier.ctaLabel),
                  ),
          ),
        ],
      ),
    );
  }
}
