import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/dio_provider.dart';
import 'package:orchestra/core/api/endpoints.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Passkey model ───────────────────────────────────────────────────────────

class _PasskeyEntry {
  _PasskeyEntry({
    required this.id,
    required this.name,
    required this.createdAt,
    this.lastUsedAt,
  });

  final int id;
  String name;
  final String createdAt;
  final String? lastUsedAt;

  factory _PasskeyEntry.fromJson(Map<String, dynamic> json) => _PasskeyEntry(
        id: (json['id'] ?? json['ID'] ?? 0) as int,
        name: (json['name'] ?? json['Name'] ?? 'Passkey') as String,
        createdAt: (json['created_at'] ?? json['CreatedAt'] ?? '').toString(),
        lastUsedAt: json['last_used_at']?.toString() ?? json['LastUsedAt']?.toString(),
      );
}

/// Passkeys settings tab — register and manage WebAuthn passkeys.
class PasskeysSettingsTab extends ConsumerStatefulWidget {
  const PasskeysSettingsTab({super.key});

  @override
  ConsumerState<PasskeysSettingsTab> createState() =>
      _PasskeysSettingsTabState();
}

class _PasskeysSettingsTabState extends ConsumerState<PasskeysSettingsTab> {
  List<_PasskeyEntry> _passkeys = [];
  bool _loading = true;
  String? _error;
  String? _successMsg;

  @override
  void initState() {
    super.initState();
    _fetchPasskeys();
  }

  Future<void> _fetchPasskeys() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<dynamic>(Endpoints.settingsPasskeys);
      final data = res.data;
      final List<dynamic> items;
      if (data is List) {
        items = data;
      } else if (data is Map && data['passkeys'] is List) {
        items = data['passkeys'] as List;
      } else {
        items = [];
      }
      if (mounted) {
        setState(() {
          _passkeys = items
              .map((e) => _PasskeyEntry.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.response?.data?['error']?.toString() ?? 'Failed to load passkeys';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _deletePasskey(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tokens = ThemeTokens.of(ctx);
        return AlertDialog(
          backgroundColor: tokens.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delete Passkey', style: TextStyle(color: tokens.fgBright)),
          content: Text(
            'This passkey will be permanently removed. You won\'t be able to use it to sign in.',
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: tokens.fgMuted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      final dio = ref.read(dioProvider);
      await dio.delete<dynamic>(Endpoints.settingsPasskey(id));
      setState(() {
        _passkeys.removeWhere((p) => p.id == id);
        _successMsg = 'Passkey deleted';
      });
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['error']?.toString() ?? 'Failed to delete');
    }
  }

  Future<void> _renamePasskey(int id, String currentName) async {
    final nameCtrl = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final tokens = ThemeTokens.of(ctx);
        return AlertDialog(
          backgroundColor: tokens.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Rename Passkey', style: TextStyle(color: tokens.fgBright)),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            style: TextStyle(color: tokens.fgBright),
            decoration: InputDecoration(
              hintText: 'Passkey name',
              hintStyle: TextStyle(color: tokens.fgDim),
              filled: true,
              fillColor: tokens.bgAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: tokens.border),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: tokens.fgMuted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    nameCtrl.dispose();

    if (newName == null || newName.isEmpty || newName == currentName) return;

    try {
      final dio = ref.read(dioProvider);
      await dio.patch<dynamic>(
        Endpoints.settingsPasskey(id),
        data: {'name': newName},
      );
      setState(() {
        final idx = _passkeys.indexWhere((p) => p.id == id);
        if (idx >= 0) _passkeys[idx].name = newName;
        _successMsg = 'Passkey renamed';
      });
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['error']?.toString() ?? 'Failed to rename');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Header ────────────────────────────────────────────────────
        _sectionHeader(tokens, l10n.passkeysTitle),
        const SizedBox(height: 4),
        Text(
          l10n.passkeysDescription,
          style: TextStyle(fontSize: 12, color: tokens.fgDim, height: 1.5),
        ),
        const SizedBox(height: 20),

        // ── Messages ──────────────────────────────────────────────────
        if (_error != null) ...[
          _messageBanner(tokens, _error!, isError: true),
          const SizedBox(height: 12),
        ],
        if (_successMsg != null) ...[
          _messageBanner(tokens, _successMsg!, isError: false),
          const SizedBox(height: 12),
        ],

        // ── Info: registration note ────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: tokens.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Passkeys can be registered from the web app. Manage your registered passkeys below.',
                  style: TextStyle(fontSize: 12, color: tokens.accent),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),
        Divider(color: tokens.border.withValues(alpha: 0.4)),
        const SizedBox(height: 20),

        // ── Registered Passkeys ───────────────────────────────────────
        _sectionHeader(tokens, l10n.registeredPasskeys),
        const SizedBox(height: 12),

        if (_loading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(color: tokens.accent, strokeWidth: 2),
            ),
          )
        else if (_passkeys.isEmpty)
          _emptyState(tokens, l10n)
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _passkeys.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: tokens.border.withValues(alpha: 0.4),
                    ),
                  _PasskeyRow(
                    entry: _passkeys[i],
                    tokens: tokens,
                    onRename: () => _renamePasskey(_passkeys[i].id, _passkeys[i].name),
                    onDelete: () => _deletePasskey(_passkeys[i].id),
                  ),
                ],
              ],
            ),
          ),
      ],
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

  Widget _emptyState(OrchestraColorTokens tokens, AppLocalizations l10n) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: tokens.bgAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          children: [
            Icon(Icons.fingerprint_rounded, size: 40, color: tokens.fgDim),
            const SizedBox(height: 12),
            Text(
              l10n.noPasskeysRegistered,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: tokens.fgMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.registerPasskeyHint,
              style: TextStyle(fontSize: 12, color: tokens.fgDim),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _messageBanner(OrchestraColorTokens tokens, String message,
          {required bool isError}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isError
              ? Colors.red.withValues(alpha: 0.12)
              : const Color(0xFF22C55E).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isError
                ? Colors.red.withValues(alpha: 0.3)
                : const Color(0xFF22C55E).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: isError ? Colors.redAccent : const Color(0xFF22C55E),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError ? Colors.redAccent : const Color(0xFF22C55E),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Passkey row widget ──────────────────────────────────────────────────────

class _PasskeyRow extends StatelessWidget {
  const _PasskeyRow({
    required this.entry,
    required this.tokens,
    required this.onRename,
    required this.onDelete,
  });

  final _PasskeyEntry entry;
  final OrchestraColorTokens tokens;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final createdDate = DateTime.tryParse(entry.createdAt);
    final createdStr = createdDate != null
        ? '${createdDate.year}-${createdDate.month.toString().padLeft(2, '0')}-${createdDate.day.toString().padLeft(2, '0')}'
        : entry.createdAt;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tokens.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.key_rounded, size: 18, color: tokens.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.fgBright,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Added $createdStr',
                  style: TextStyle(fontSize: 10, color: tokens.fgDim),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onRename,
                icon: Icon(Icons.edit_rounded,
                    size: 16, color: tokens.fgMuted),
                tooltip: l10n.rename,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: Color(0xFFEF4444)),
                tooltip: l10n.delete,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
