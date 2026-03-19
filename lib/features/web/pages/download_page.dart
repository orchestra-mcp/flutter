import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';
import 'package:url_launcher/url_launcher.dart';

const _baseUrl = 'https://github.com/orchestra-mcp/framework/releases/latest';

/// Download page — per-platform binary download links.
class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  int _selected = 0;

  static const _platforms = ['macOS', 'Windows', 'Linux', 'iOS', 'Android'];
  static const _assets = [
    'orchestra_darwin_arm64.tar.gz',
    'orchestra_windows_amd64.zip',
    'orchestra_linux_amd64.tar.gz',
    'TestFlight',
    'Google Play',
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).downloadLabel),
        backgroundColor: tokens.bg,
        foregroundColor: tokens.fgBright,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                _platforms.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_platforms[i]),
                    selected: _selected == i,
                    onSelected: (_) => setState(() => _selected = i),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _platforms[_selected],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: tokens.fgBright,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.download_rounded),
                    label: Text(
                      AppLocalizations.of(
                        context,
                      ).downloadItem(_assets[_selected]),
                    ),
                    onPressed: () => launchUrl(Uri.parse(_baseUrl)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
