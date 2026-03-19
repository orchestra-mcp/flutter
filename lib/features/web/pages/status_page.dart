import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

/// Public status page — health indicators per service.
class StatusPage extends StatelessWidget {
  const StatusPage({super.key});

  static const _services = ['API', 'Auth', 'Sync', 'Storage', 'WebSocket'];

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(title: Text(l10n.status), backgroundColor: tokens.bg, foregroundColor: tokens.fgBright, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          GlassCard(
            child: Column(
              children: _services.map((svc) => ListTile(
                    leading: const CircleAvatar(radius: 6, backgroundColor: Colors.green),
                    title: Text(svc, style: TextStyle(color: tokens.fgBright)),
                    trailing: Text(l10n.operational, style: TextStyle(color: Colors.green, fontSize: 12)),
                  )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
