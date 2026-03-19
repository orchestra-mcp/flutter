import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

/// Public pricing page — three plan tiers.
class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(title: Text(AppLocalizations.of(context).pricing), backgroundColor: tokens.bg, foregroundColor: tokens.fgBright, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          _PlanCard(name: 'Free', price: r'$0', features: ['5 projects', '3 agents', 'Community support']),
          SizedBox(height: 16),
          _PlanCard(name: 'Pro', price: r'$12/mo', features: ['Unlimited projects', '20 agents', 'Priority support', 'Health tracking']),
          SizedBox(height: 16),
          _PlanCard(name: 'Team', price: r'$49/mo', features: ['Everything in Pro', 'Team workspace', 'SSO', 'Audit logs']),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.name, required this.price, required this.features});
  final String name;
  final String price;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: tokens.fgBright)),
          Text(price, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: tokens.accent)),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Icon(Icons.check, size: 16, color: tokens.accent),
                  const SizedBox(width: 8),
                  Text(f, style: TextStyle(color: tokens.fgBright, fontSize: 14)),
                ]),
              )),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () {}, child: Text(AppLocalizations.of(context).getItem(name)))),
        ],
      ),
    );
  }
}
