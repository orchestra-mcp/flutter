import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/features/devtools/providers/devtools_selection_provider.dart';
import 'package:orchestra/features/devtools/providers/secrets_provider.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ── Category metadata ────────────────────────────────────────────────────────

const _categories = [
  'api_key',
  'token',
  'env',
  'database',
  'password',
  'general',
];

Color _categoryColor(String category) {
  return switch (category) {
    'api_key' => const Color(0xFF3B82F6),
    'token' => const Color(0xFF8B5CF6),
    'env' => const Color(0xFF22C55E),
    'database' => const Color(0xFFF97316),
    'password' => const Color(0xFFEF4444),
    'general' => const Color(0xFF6B7280),
    _ => const Color(0xFF6B7280),
  };
}

String _categoryLabel(String category) {
  return switch (category) {
    'api_key' => 'API Key',
    'token' => 'Token',
    'env' => 'Env',
    'database' => 'Database',
    'password' => 'Password',
    'general' => 'General',
    _ => category,
  };
}

// ── Main screen ─────────────────────────────────────────────────────────────

/// Secrets Manager screen with CRUD operations, search, category filtering,
/// .env import, and export to clipboard.
class SecretsScreen extends ConsumerStatefulWidget {
  const SecretsScreen({super.key});

  @override
  ConsumerState<SecretsScreen> createState() => _SecretsScreenState();
}

class _SecretsScreenState extends ConsumerState<SecretsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _categoryFilter;

  // Tracks which secrets have their value revealed.
  final Set<String> _revealedSecrets = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filtered secrets ──────────────────────────────────────────────────────

  List<Secret> _filterSecrets(List<Secret> secrets) {
    var filtered = secrets;

    if (_categoryFilter != null) {
      filtered = filtered.where((s) => s.category == _categoryFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final lower = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return s.name.toLowerCase().contains(lower) ||
            (s.description?.toLowerCase().contains(lower) ?? false) ||
            s.tags.any((t) => t.toLowerCase().contains(lower));
      }).toList();
    }

    return filtered;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _revealSecret(String secretId) async {
    setState(() => _revealedSecrets.add(secretId));
  }

  void _hideSecret(String secretId) {
    setState(() => _revealedSecrets.remove(secretId));
  }

  Future<void> _copySecret(String secretId) async {
    try {
      final notifier = ref.read(secretsProvider.notifier);
      final secret = await notifier.getSecret(secretId);
      if (secret.value != null && mounted) {
        await Clipboard.setData(ClipboardData(text: secret.value!));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied "${secret.name}" to clipboard'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteSecret(Secret secret) async {
    final tokens = ThemeTokens.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        title: Text('Delete Secret', style: TextStyle(color: tokens.fgBright)),
        content: Text(
          'Permanently delete "${secret.name}"? This cannot be undone.',
          style: TextStyle(color: tokens.fgMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: tokens.fgMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(secretsProvider.notifier).deleteSecret(secret.id);
      _revealedSecrets.remove(secret.id);
    }
  }

  Future<void> _exportSecrets() async {
    try {
      final notifier = ref.read(secretsProvider.notifier);
      final output = await notifier.exportEnv();
      if (output.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No secrets to export'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      await Clipboard.setData(ClipboardData(text: output));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exported .env copied to clipboard'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showCreateDialog({Secret? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final valueCtrl = TextEditingController(text: existing?.value ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final scopeCtrl = TextEditingController(text: existing?.scope ?? 'global');
    final tagsCtrl = TextEditingController(
      text: existing?.tags.join(', ') ?? '',
    );
    var selectedCategory = existing?.category ?? 'general';
    final tokens = ThemeTokens.of(context);
    final isEditing = existing != null;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: tokens.bgAlt,
              title: Text(
                isEditing ? 'Edit Secret' : 'New Secret',
                style: TextStyle(color: tokens.fgBright),
              ),
              content: SizedBox(
                width: isDesktop ? 420 : double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name
                      _DialogTextField(
                        controller: nameCtrl,
                        label: 'Name',
                        hint: 'MY_API_KEY',
                        tokens: tokens,
                        autofocus: true,
                        monospace: true,
                      ),
                      const SizedBox(height: 12),

                      // Value
                      _DialogTextField(
                        controller: valueCtrl,
                        label: 'Value',
                        hint: 'sk-...',
                        tokens: tokens,
                        obscure: true,
                        monospace: true,
                      ),
                      const SizedBox(height: 12),

                      // Category dropdown
                      _buildCategoryDropdown(tokens, selectedCategory, (value) {
                        setDialogState(() => selectedCategory = value);
                      }),
                      const SizedBox(height: 12),

                      // Description
                      _DialogTextField(
                        controller: descCtrl,
                        label: 'Description (optional)',
                        hint: 'Production API key for Stripe',
                        tokens: tokens,
                      ),
                      const SizedBox(height: 12),

                      // Scope
                      _DialogTextField(
                        controller: scopeCtrl,
                        label: 'Scope',
                        hint: 'global',
                        tokens: tokens,
                      ),
                      const SizedBox(height: 12),

                      // Tags
                      _DialogTextField(
                        controller: tagsCtrl,
                        label: 'Tags (comma-separated)',
                        hint: 'production, stripe',
                        tokens: tokens,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: tokens.fgMuted),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final value = valueCtrl.text.trim();
                    if (name.isEmpty) return;
                    if (!isEditing && value.isEmpty) return;

                    Navigator.pop(ctx);

                    final notifier = ref.read(secretsProvider.notifier);
                    final tags = tagsCtrl.text
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .join(',');

                    if (isEditing) {
                      await notifier.updateSecret(
                        existing.id,
                        name: name,
                        value: value.isNotEmpty ? value : null,
                        category: selectedCategory,
                        description: descCtrl.text.trim().isNotEmpty
                            ? descCtrl.text.trim()
                            : null,
                        scope: scopeCtrl.text.trim().isNotEmpty
                            ? scopeCtrl.text.trim()
                            : null,
                        tags: tags.isNotEmpty ? tags : null,
                      );
                    } else {
                      await notifier.createSecret(
                        name: name,
                        value: value,
                        category: selectedCategory,
                        description: descCtrl.text.trim().isNotEmpty
                            ? descCtrl.text.trim()
                            : null,
                        scope: scopeCtrl.text.trim().isNotEmpty
                            ? scopeCtrl.text.trim()
                            : null,
                        tags: tags.isNotEmpty ? tags : null,
                      );
                    }
                  },
                  child: Text(
                    isEditing ? 'Save' : 'Create',
                    style: TextStyle(color: tokens.accent),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameCtrl.dispose();
      valueCtrl.dispose();
      descCtrl.dispose();
      scopeCtrl.dispose();
      tagsCtrl.dispose();
    });
  }

  void _showImportDialog() {
    final contentCtrl = TextEditingController();
    var importCategory = 'env';
    var importScope = 'global';
    final tokens = ThemeTokens.of(context);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: tokens.bgAlt,
              title: Text(
                'Import .env',
                style: TextStyle(color: tokens.fgBright),
              ),
              content: SizedBox(
                width: isDesktop ? 480 : double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paste .env contents below. Each line should be KEY=VALUE.',
                      style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),

                    // Content text area
                    TextField(
                      controller: contentCtrl,
                      maxLines: 8,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 12,
                        fontFamily: 'JetBrains Mono',
                        fontFamilyFallback: const ['monospace'],
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'DATABASE_URL=postgres://...\nAPI_KEY=sk-...\nSECRET_TOKEN=abc123',
                        hintStyle: TextStyle(
                          color: tokens.fgDim.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: tokens.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: tokens.borderFaint),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: tokens.borderFaint),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: tokens.accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category + Scope row
                    Row(
                      children: [
                        Expanded(
                          child: _buildCategoryDropdown(
                            tokens,
                            importCategory,
                            (value) {
                              setDialogState(() => importCategory = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DialogTextField(
                            controller: TextEditingController(
                              text: importScope,
                            ),
                            label: 'Scope',
                            hint: 'global',
                            tokens: tokens,
                            onChanged: (v) => importScope = v,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: tokens.fgMuted),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final content = contentCtrl.text.trim();
                    if (content.isEmpty) return;

                    Navigator.pop(ctx);

                    await ref
                        .read(secretsProvider.notifier)
                        .importEnv(
                          content,
                          category: importCategory,
                          scope: importScope,
                        );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Secrets imported successfully'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Text('Import', style: TextStyle(color: tokens.accent)),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      contentCtrl.dispose();
    });
  }

  // ── Category dropdown builder ─────────────────────────────────────────────

  Widget _buildCategoryDropdown(
    OrchestraColorTokens tokens,
    String current,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: current,
      dropdownColor: tokens.bgAlt,
      style: TextStyle(color: tokens.fgBright, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle: TextStyle(color: tokens.fgDim),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: tokens.borderFaint),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: tokens.accent),
        ),
      ),
      items: _categories.map((c) {
        final color = _categoryColor(c);
        return DropdownMenuItem(
          value: c,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(_categoryLabel(c)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    // On desktop the sidebar IS the list — show only the detail/empty state.
    if (isDesktop) {
      return _buildDesktop(tokens);
    }

    // Mobile: full-page list with search & header.
    final asyncSecrets = ref.watch(secretsProvider);
    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          _buildAppBar(tokens),
          Expanded(
            child: asyncSecrets.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: tokens.accent)),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load secrets:\n$e',
                    style: TextStyle(color: tokens.fgMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (secrets) {
                final filtered = _filterSecrets(secrets);
                if (secrets.isEmpty) return _buildEmptyState(tokens);
                if (filtered.isEmpty) return _buildNoResultsState(tokens);
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _buildSecretCard(tokens, filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(),
        backgroundColor: tokens.accent,
        child: Icon(
          Icons.add_rounded,
          color: tokens.isLight ? Colors.white : tokens.bg,
        ),
      ),
    );
  }

  // ── Desktop detail view ────────────────────────────────────────────────────

  Widget _buildDesktop(OrchestraColorTokens tokens) {
    final selectedId = ref.watch(selectedSecretIdProvider);

    if (selectedId == null) {
      return Scaffold(
        backgroundColor: tokens.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.vpn_key_rounded,
                size: 48,
                color: tokens.fgDim.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Select a secret',
                style: TextStyle(
                  color: tokens.fgMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose from the sidebar or tap + to create one.',
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final asyncSecrets = ref.watch(secretsProvider);
    return asyncSecrets.when(
      loading: () => Scaffold(
        backgroundColor: tokens.bg,
        body: Center(child: CircularProgressIndicator(color: tokens.accent)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: tokens.bg,
        body: Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
        ),
      ),
      data: (secrets) {
        final secret = secrets.where((s) => s.id == selectedId).firstOrNull;
        if (secret == null) {
          return Scaffold(
            backgroundColor: tokens.bg,
            body: Center(
              child: Text(
                'Secret not found.',
                style: TextStyle(color: tokens.fgMuted, fontSize: 13),
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: tokens.bg,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildSecretCard(tokens, secret),
          ),
        );
      },
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar(OrchestraColorTokens tokens) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        isDesktop ? 16 : MediaQuery.paddingOf(context).top + 12,
        12,
        12,
      ),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        border: Border(
          bottom: BorderSide(color: tokens.borderFaint, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row
          Row(
            children: [
              Icon(Icons.key_rounded, color: tokens.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Secrets',
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Import button
              _SmallActionButton(
                icon: Icons.upload_file_rounded,
                label: 'Import',
                color: tokens.fgMuted,
                onTap: _showImportDialog,
              ),
              const SizedBox(width: 4),

              // Export button
              _SmallActionButton(
                icon: Icons.download_rounded,
                label: 'Export',
                color: tokens.fgMuted,
                onTap: _exportSecrets,
              ),

              if (isDesktop) ...[
                const SizedBox(width: 8),
                // New secret button
                TextButton.icon(
                  onPressed: () => _showCreateDialog(),
                  icon: Icon(Icons.add_rounded, size: 16, color: tokens.accent),
                  label: Text(
                    'New',
                    style: TextStyle(color: tokens.accent, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: tokens.accent.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Search + category filter row
          Row(
            children: [
              // Search field
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: tokens.fgBright, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search secrets...',
                      hintStyle: TextStyle(
                        color: tokens.fgDim.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: tokens.fgDim,
                        size: 18,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: tokens.fgDim,
                              ),
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: tokens.borderFaint),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: tokens.borderFaint),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: tokens.accent),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Category filter
              SizedBox(
                height: 34,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: tokens.borderFaint),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _categoryFilter,
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'All',
                          style: TextStyle(color: tokens.fgDim, fontSize: 13),
                        ),
                      ),
                      dropdownColor: tokens.bgAlt,
                      style: TextStyle(color: tokens.fgBright, fontSize: 13),
                      icon: Icon(
                        Icons.filter_list_rounded,
                        size: 16,
                        color: _categoryFilter != null
                            ? tokens.accent
                            : tokens.fgDim,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      borderRadius: BorderRadius.circular(8),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'All Categories',
                            style: TextStyle(color: tokens.fgBright),
                          ),
                        ),
                        ..._categories.map((c) {
                          final color = _categoryColor(c);
                          return DropdownMenuItem<String?>(
                            value: c,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(_categoryLabel(c)),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _categoryFilter = value);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Secret card ───────────────────────────────────────────────────────────

  Widget _buildSecretCard(OrchestraColorTokens tokens, Secret secret) {
    final isRevealed = _revealedSecrets.contains(secret.id);
    final catColor = _categoryColor(secret.category);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      margin: EdgeInsets.zero,
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: name + badges + actions ──────────────────────────
          Row(
            children: [
              // Name
              Expanded(
                child: Text(
                  secret.name,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'JetBrains Mono',
                    fontFamilyFallback: const ['monospace'],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Action buttons
              _SmallIconButton(
                icon: isRevealed
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: tokens.fgMuted,
                tooltip: isRevealed ? 'Hide' : 'Reveal',
                onTap: () => isRevealed
                    ? _hideSecret(secret.id)
                    : _revealSecret(secret.id),
              ),
              _SmallIconButton(
                icon: Icons.copy_rounded,
                color: tokens.fgMuted,
                tooltip: 'Copy',
                onTap: () => _copySecret(secret.id),
              ),
              _SmallIconButton(
                icon: Icons.edit_rounded,
                color: tokens.fgMuted,
                tooltip: 'Edit',
                onTap: () => _showCreateDialog(existing: secret),
              ),
              _SmallIconButton(
                icon: Icons.delete_outline_rounded,
                color: const Color(0xFFEF4444).withValues(alpha: 0.7),
                tooltip: 'Delete',
                onTap: () => _deleteSecret(secret),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Badges row: category + scope ──────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              // Category badge
              _Badge(label: _categoryLabel(secret.category), color: catColor),
              // Scope badge
              _Badge(label: secret.scope, color: tokens.fgDim),
              // Tags
              ...secret.tags.map(
                (tag) => _Badge(
                  label: tag,
                  color: tokens.accent.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),

          // ── Description ───────────────────────────────────────────────
          if (secret.description != null && secret.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              secret.description!,
              style: TextStyle(color: tokens.fgMuted, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 8),

          // ── Masked / revealed value ───────────────────────────────────
          if (isRevealed)
            _RevealedValue(secretId: secret.id, tokens: tokens)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.bg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: tokens.borderFaint, width: 0.5),
              ),
              child: Text(
                secret.maskedValue ?? '********',
                style: TextStyle(
                  color: tokens.fgDim,
                  fontSize: 12,
                  fontFamily: 'JetBrains Mono',
                  fontFamilyFallback: const ['monospace'],
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState(OrchestraColorTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.key_off_rounded,
              size: 40,
              color: tokens.fgDim.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No secrets stored',
              style: TextStyle(
                color: tokens.fgMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create a secret or import from a .env file.',
              style: TextStyle(color: tokens.fgDim, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: () => _showCreateDialog(),
                  icon: Icon(Icons.add_rounded, size: 16, color: tokens.accent),
                  label: Text(
                    'New Secret',
                    style: TextStyle(color: tokens.accent, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _showImportDialog,
                  icon: Icon(
                    Icons.upload_file_rounded,
                    size: 16,
                    color: tokens.fgMuted,
                  ),
                  label: Text(
                    'Import .env',
                    style: TextStyle(color: tokens.fgMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── No results state ──────────────────────────────────────────────────────

  Widget _buildNoResultsState(OrchestraColorTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: tokens.fgDim.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No matching secrets',
              style: TextStyle(
                color: tokens.fgMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your search or filter.',
              style: TextStyle(color: tokens.fgDim, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Revealed value widget (fetches decrypted value) ──────────────────────────

class _RevealedValue extends ConsumerWidget {
  const _RevealedValue({required this.secretId, required this.tokens});

  final String secretId;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSecret = ref.watch(secretDetailProvider(secretId));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: tokens.accent.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: asyncSecret.when(
        loading: () => SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
            color: tokens.accent,
            strokeWidth: 1.5,
          ),
        ),
        error: (e, _) => Text(
          'Failed to reveal: $e',
          style: const TextStyle(
            color: Color(0xFFEF4444),
            fontSize: 12,
            fontFamily: 'JetBrains Mono',
            fontFamilyFallback: ['monospace'],
          ),
        ),
        data: (secret) => SelectableText(
          secret.value ?? '(empty)',
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 12,
            fontFamily: 'JetBrains Mono',
            fontFamilyFallback: const ['monospace'],
          ),
        ),
      ),
    );
  }
}

// ── Dialog text field ────────────────────────────────────────────────────────

class _DialogTextField extends StatelessWidget {
  const _DialogTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.tokens,
    this.autofocus = false,
    this.obscure = false,
    this.monospace = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final OrchestraColorTokens tokens;
  final bool autofocus;
  final bool obscure;
  final bool monospace;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      obscureText: obscure,
      onChanged: onChanged,
      style: TextStyle(
        color: tokens.fgBright,
        fontSize: 14,
        fontFamily: monospace ? 'JetBrains Mono' : null,
        fontFamilyFallback: monospace ? const ['monospace'] : null,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: tokens.fgDim),
        hintText: hint,
        hintStyle: TextStyle(color: tokens.fgDim.withValues(alpha: 0.5)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: tokens.borderFaint),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: tokens.accent),
        ),
      ),
    );
  }
}

// ── Badge widget ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Small icon button ────────────────────────────────────────────────────────

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}

// ── Small action button (icon + label) ───────────────────────────────────────

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 15),
              if (isDesktop) ...[
                const SizedBox(width: 4),
                Text(label, style: TextStyle(color: color, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
