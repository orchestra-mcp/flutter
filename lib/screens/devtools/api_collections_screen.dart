import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/features/devtools/providers/api_collection_provider.dart';
import 'package:orchestra/features/devtools/providers/devtools_selection_provider.dart';
import 'package:orchestra/screens/devtools/widgets/api_request_builder.dart';
import 'package:orchestra/screens/devtools/widgets/api_response_viewer.dart';
import 'package:orchestra/widgets/entity_search_bar.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ── Method color helper ──────────────────────────────────────────────────────

Color methodColor(String method) {
  return switch (method.toUpperCase()) {
    'GET' => const Color(0xFF22C55E),
    'POST' => const Color(0xFF3B82F6),
    'PUT' => const Color(0xFFF59E0B),
    'PATCH' => const Color(0xFF8B5CF6),
    'DELETE' => const Color(0xFFEF4444),
    _ => const Color(0xFF6B7280),
  };
}

// ── Main screen ──────────────────────────────────────────────────────────────

/// API Collections screen.
///
/// Desktop: master list of collections on the left (260 px), request builder
/// + response viewer on the right. Clicking a collection expands its endpoints;
/// clicking an endpoint loads it into the builder.
///
/// Mobile: collections list → builder + response stacked (same as before).
class ApiCollectionsScreen extends ConsumerStatefulWidget {
  const ApiCollectionsScreen({super.key});

  @override
  ConsumerState<ApiCollectionsScreen> createState() =>
      _ApiCollectionsScreenState();
}

class _ApiCollectionsScreenState extends ConsumerState<ApiCollectionsScreen> {
  final _builderKey = GlobalKey<ApiRequestBuilderState>();
  final _searchController = TextEditingController();
  String _search = '';

  String? _selectedCollectionId;
  ApiEndpoint? _selectedEndpoint;
  final Set<String> _expandedCollections = {};

  ApiResponse? _response;
  String? _responseError;
  bool _isSending = false;

  // Mobile nav depth: 0 = list, 1 = builder+response
  int _mobileDepth = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<ApiCollection> _filter(List<ApiCollection> all) {
    if (_search.isEmpty) return all;
    final q = _search.toLowerCase();
    return all
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            (c.description?.toLowerCase().contains(q) ?? false) ||
            c.endpoints.any((e) => e.name.toLowerCase().contains(q)))
        .toList();
  }

  Future<void> _sendRequest(RequestBuilderData data) async {
    if (data.url.isEmpty) return;
    setState(() {
      _isSending = true;
      _response = null;
      _responseError = null;
    });
    try {
      final resp = await ref.read(apiCollectionProvider.notifier).sendRequest(
            method: data.method,
            url: data.url,
            headers: data.headers,
            body: data.body,
            bodyType: data.bodyType,
            auth: data.auth,
          );
      if (mounted) setState(() { _response = resp; _isSending = false; });
    } catch (e) {
      if (mounted) setState(() { _responseError = e.toString(); _isSending = false; });
    }
  }

  void _selectEndpoint(ApiEndpoint endpoint, String collectionId) {
    setState(() {
      _selectedCollectionId = collectionId;
      _selectedEndpoint = endpoint;
      _response = null;
      _responseError = null;
      _mobileDepth = 1;
    });
    _builderKey.currentState?.loadEndpoint(
      method: endpoint.method,
      url: endpoint.url,
      body: endpoint.body,
      bodyType: endpoint.bodyType,
      headers: endpoint.headers,
    );
  }

  Future<void> _deleteCollection(String id) async {
    final tokens = ThemeTokens.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        title: Text('Delete Collection', style: TextStyle(color: tokens.fgBright)),
        content: Text(
          'This will permanently delete this collection and all its endpoints.',
          style: TextStyle(color: tokens.fgMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: tokens.fgMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(apiCollectionProvider.notifier).deleteCollection(id);
      if (mounted && _selectedCollectionId == id) {
        setState(() {
          _selectedCollectionId = null;
          _selectedEndpoint = null;
          _response = null;
          _responseError = null;
          _mobileDepth = 0;
        });
      }
    }
  }

  void _showNewCollectionDialog() {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final tokens = ThemeTokens.of(context);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        title: Text('New Collection', style: TextStyle(color: tokens.fgBright)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InlineField(controller: nameCtrl, label: 'Collection Name', hint: 'My API', tokens: tokens, autofocus: true),
            const SizedBox(height: 12),
            _InlineField(controller: urlCtrl, label: 'Base URL (optional)', hint: 'https://api.example.com', tokens: tokens),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: tokens.fgMuted)),
          ),
          TextButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await ref.read(apiCollectionProvider.notifier).saveRequest(
                    collectionName: name,
                    name: 'Example Request',
                    method: 'GET',
                    url: urlCtrl.text.trim().isEmpty
                        ? 'https://api.example.com'
                        : urlCtrl.text.trim(),
                  );
            },
            child: Text('Create', style: TextStyle(color: tokens.accent)),
          ),
        ],
      ),
    ).then((_) {
      nameCtrl.dispose();
      urlCtrl.dispose();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return isDesktop ? _buildDesktop() : _buildMobile();
  }

  Widget _buildDesktop() {
    final tokens = ThemeTokens.of(context);

    // On desktop the global sidebar IS the list — sync selection from shared providers.
    final providerCollectionId = ref.watch(selectedCollectionIdProvider);
    final providerEndpoint = ref.watch(selectedEndpointProvider);

    // If the sidebar selected a different collection, expand it and load the
    // first endpoint automatically so the content area is never blank.
    if (providerCollectionId != null &&
        providerCollectionId != _selectedCollectionId) {
      final collections = ref.read(apiCollectionProvider).value ?? [];
      final col =
          collections.where((c) => c.id == providerCollectionId).firstOrNull;
      if (col != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _expandedCollections.add(col.id);
          if (col.endpoints.isNotEmpty) {
            _selectEndpoint(col.endpoints.first, col.id);
          } else {
            setState(() {
              _selectedCollectionId = col.id;
              _selectedEndpoint = null;
            });
          }
        });
      }
    }

    // If sidebar explicitly selected an endpoint, load it.
    if (providerEndpoint != null && providerEndpoint != _selectedEndpoint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectEndpoint(providerEndpoint, providerCollectionId ?? '');
      });
    }

    final endpoint = _selectedEndpoint;
    return Scaffold(
      backgroundColor: tokens.bg,
      body: endpoint != null
          ? Row(
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                          right: BorderSide(
                              color: tokens.borderFaint, width: 0.5)),
                    ),
                    child: ApiRequestBuilder(
                      key: _builderKey,
                      initialMethod: endpoint.method,
                      initialUrl: endpoint.url,
                      initialHeaders: endpoint.headers,
                      initialBody: endpoint.body,
                      initialBodyType: endpoint.bodyType,
                      onSend: _sendRequest,
                      isSending: _isSending,
                    ),
                  ),
                ),
                SizedBox(
                  width: 340,
                  child:
                      ApiResponseViewer(response: _response, error: _responseError),
                ),
              ],
            )
          : _buildPlaceholder(tokens),
    );
  }

  Widget _buildPlaceholder(OrchestraColorTokens tokens) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.api_rounded, size: 48, color: tokens.fgDim.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            'Select an endpoint',
            style: TextStyle(color: tokens.fgMuted, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a collection and endpoint from the list.',
            style: TextStyle(color: tokens.fgDim, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile() {
    final tokens = ThemeTokens.of(context);
    if (_mobileDepth == 0) {
      return Scaffold(
        backgroundColor: tokens.bg,
        body: SafeArea(child: _buildList(tokens)),
        floatingActionButton: FloatingActionButton(
          onPressed: _showNewCollectionDialog,
          backgroundColor: tokens.accent,
          child: Icon(Icons.add_rounded, color: tokens.isLight ? Colors.white : tokens.bg),
        ),
      );
    }
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.bgAlt,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: tokens.fgBright),
          onPressed: () => setState(() => _mobileDepth = 0),
        ),
        title: Text(
          _selectedEndpoint?.name ?? 'Request',
          style: TextStyle(color: tokens.fgBright, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: tokens.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: ApiRequestBuilder(
              key: _builderKey,
              initialMethod: _selectedEndpoint?.method,
              initialUrl: _selectedEndpoint?.url,
              initialHeaders: _selectedEndpoint?.headers,
              initialBody: _selectedEndpoint?.body,
              initialBodyType: _selectedEndpoint?.bodyType,
              onSend: _sendRequest,
              isSending: _isSending,
            ),
          ),
          Container(height: 0.5, color: tokens.borderFaint),
          Expanded(
            flex: 4,
            child: ApiResponseViewer(response: _response, error: _responseError),
          ),
        ],
      ),
    );
  }

  // ── Collections list ──────────────────────────────────────────────────────

  Widget _buildList(OrchestraColorTokens tokens) {
    final asyncCollections = ref.watch(apiCollectionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search + add
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: EntitySearchBar(
                  hintText: 'Search…',
                  controller: _searchController,
                  onChanged: (v) => setState(() => _search = v),
                  tokens: tokens,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: Icon(Icons.add_rounded, color: tokens.accent, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: tokens.accent.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showNewCollectionDialog,
                tooltip: 'New Collection',
              ),
            ],
          ),
        ),

        // Collection tiles
        Expanded(
          child: asyncCollections.when(
            loading: () => Center(child: CircularProgressIndicator(color: tokens.accent)),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load:\n$e', style: TextStyle(color: tokens.fgMuted, fontSize: 13), textAlign: TextAlign.center),
              ),
            ),
            data: (all) {
              final list = _filter(all);
              if (list.isEmpty) return _buildEmpty(tokens);
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                itemCount: list.length,
                itemBuilder: (_, i) => _buildCollectionTile(tokens, list[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(OrchestraColorTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_rounded, size: 40, color: tokens.fgDim.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No collections', style: TextStyle(color: tokens.fgMuted, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Create a collection to organize your API requests.',
              style: TextStyle(color: tokens.fgDim, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _showNewCollectionDialog,
              icon: Icon(Icons.add_rounded, size: 16, color: tokens.accent),
              label: Text('New Collection', style: TextStyle(color: tokens.accent, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Collection tile ───────────────────────────────────────────────────────

  Widget _buildCollectionTile(OrchestraColorTokens tokens, ApiCollection collection) {
    final isExpanded = _expandedCollections.contains(collection.id);
    final isActive = _selectedCollectionId == collection.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          margin: const EdgeInsets.only(bottom: 2),
          borderRadius: 10,
          onTap: () => setState(() {
            if (isExpanded) {
              _expandedCollections.remove(collection.id);
            } else {
              _expandedCollections.add(collection.id);
            }
          }),
          child: Row(
            children: [
              Icon(
                isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded,
                color: tokens.fgMuted,
                size: 18,
              ),
              const SizedBox(width: 6),
              Icon(Icons.folder_rounded, size: 16, color: isActive ? tokens.accent : const Color(0xFFFBBF24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name,
                      style: TextStyle(
                        color: isActive ? tokens.accent : tokens.fgBright,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (collection.baseUrl != null && collection.baseUrl!.isNotEmpty)
                      Text(
                        collection.baseUrl!,
                        style: TextStyle(color: tokens.fgDim, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.fgDim.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${collection.endpoints.length}',
                  style: TextStyle(color: tokens.fgDim, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _deleteCollection(collection.id),
                child: Icon(Icons.close_rounded, size: 14, color: tokens.fgDim.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: collection.endpoints.map((ep) => _buildEndpointTile(tokens, ep, collection.id)).toList(),
            ),
          ),
      ],
    );
  }

  // ── Endpoint tile ─────────────────────────────────────────────────────────

  Widget _buildEndpointTile(OrchestraColorTokens tokens, ApiEndpoint endpoint, String collectionId) {
    final isActive = _selectedEndpoint?.id == endpoint.id && _selectedCollectionId == collectionId;

    return InkWell(
      onTap: () => _selectEndpoint(endpoint, collectionId),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isActive ? tokens.accent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: tokens.accent.withValues(alpha: 0.3), width: 0.5) : null,
        ),
        child: Row(
          children: [
            _MethodBadge(method: endpoint.method),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                endpoint.name,
                style: TextStyle(
                  color: isActive ? tokens.accent : tokens.fgBright,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Method badge ─────────────────────────────────────────────────────────────

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method});
  final String method;

  @override
  Widget build(BuildContext context) {
    final color = methodColor(method);
    final label = method.length > 4 ? method.substring(0, 4) : method;
    return Container(
      width: 38,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3),
      ),
    );
  }
}

// ── Simple dialog text field ──────────────────────────────────────────────────

class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.tokens,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final OrchestraColorTokens tokens;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      style: TextStyle(color: tokens.fgBright, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: tokens.fgDim),
        hintText: hint,
        hintStyle: TextStyle(color: tokens.fgDim.withValues(alpha: 0.5)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: tokens.borderFaint)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: tokens.accent)),
      ),
    );
  }
}
