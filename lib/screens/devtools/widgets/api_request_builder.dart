import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';

// ── HTTP method colors ──────────────────────────────────────────────────────

const _kMethods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'];

Color methodColor(String method) => switch (method.toUpperCase()) {
  'GET' => const Color(0xFF22C55E),
  'POST' => const Color(0xFF3B82F6),
  'PUT' => const Color(0xFFF97316),
  'PATCH' => const Color(0xFFEAB308),
  'DELETE' => const Color(0xFFEF4444),
  _ => const Color(0xFF6B7280),
};

// ── Header entry model ──────────────────────────────────────────────────────

class _HeaderEntry {
  _HeaderEntry({String? key, String? value})
    : keyController = TextEditingController(text: key ?? ''),
      valueController = TextEditingController(text: value ?? '');

  final TextEditingController keyController;
  final TextEditingController valueController;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

// ── Request builder result ──────────────────────────────────────────────────

/// The data bundle returned by the request builder when the user taps Send.
class RequestBuilderData {
  const RequestBuilderData({
    required this.method,
    required this.url,
    this.headers,
    this.body,
    this.bodyType,
    this.auth,
  });

  final String method;
  final String url;
  final Map<String, dynamic>? headers;
  final String? body;
  final String? bodyType;
  final Map<String, dynamic>? auth;
}

// ── Widget ──────────────────────────────────────────────────────────────────

/// Centre-pane request builder with method dropdown, URL field, Send button,
/// and tabs for Params, Headers, Body, and Auth.
class ApiRequestBuilder extends StatefulWidget {
  const ApiRequestBuilder({
    super.key,
    this.initialMethod,
    this.initialUrl,
    this.initialHeaders,
    this.initialBody,
    this.initialBodyType,
    required this.onSend,
    this.isSending = false,
  });

  final String? initialMethod;
  final String? initialUrl;
  final Map<String, dynamic>? initialHeaders;
  final String? initialBody;
  final String? initialBodyType;

  /// Called when the user taps the Send button.
  final void Function(RequestBuilderData data) onSend;

  /// When true the Send button shows a loading indicator.
  final bool isSending;

  @override
  State<ApiRequestBuilder> createState() => ApiRequestBuilderState();
}

class ApiRequestBuilderState extends State<ApiRequestBuilder>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _method;
  late TextEditingController _urlController;
  late TextEditingController _bodyController;
  String _bodyType = 'json';

  // Auth state
  String _authType = 'none';
  final _bearerTokenController = TextEditingController();
  final _basicUserController = TextEditingController();
  final _basicPassController = TextEditingController();
  final _apiKeyNameController = TextEditingController();
  final _apiKeyValueController = TextEditingController();

  // Headers
  final List<_HeaderEntry> _headers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _method = widget.initialMethod?.toUpperCase() ?? 'GET';
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
    _bodyController = TextEditingController(text: widget.initialBody ?? '');
    _bodyType = widget.initialBodyType ?? 'json';

    if (widget.initialHeaders != null && widget.initialHeaders!.isNotEmpty) {
      for (final entry in widget.initialHeaders!.entries) {
        _headers.add(
          _HeaderEntry(key: entry.key, value: entry.value?.toString() ?? ''),
        );
      }
    }
    if (_headers.isEmpty) {
      _headers.add(_HeaderEntry());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _bodyController.dispose();
    _bearerTokenController.dispose();
    _basicUserController.dispose();
    _basicPassController.dispose();
    _apiKeyNameController.dispose();
    _apiKeyValueController.dispose();
    for (final h in _headers) {
      h.dispose();
    }
    super.dispose();
  }

  /// Populate the builder from an external endpoint selection.
  void loadEndpoint({
    required String method,
    required String url,
    String? body,
    String? bodyType,
    Map<String, dynamic>? headers,
  }) {
    setState(() {
      _method = method.toUpperCase();
      _urlController.text = url;
      _bodyController.text = body ?? '';
      if (bodyType != null) _bodyType = bodyType;
      for (final h in _headers) {
        h.dispose();
      }
      _headers.clear();
      if (headers != null && headers.isNotEmpty) {
        for (final entry in headers.entries) {
          _headers.add(
            _HeaderEntry(key: entry.key, value: entry.value?.toString() ?? ''),
          );
        }
      }
      if (_headers.isEmpty) {
        _headers.add(_HeaderEntry());
      }
    });
  }

  RequestBuilderData _collectData() {
    // Build headers map
    final headersMap = <String, dynamic>{};
    for (final h in _headers) {
      final k = h.keyController.text.trim();
      final v = h.valueController.text.trim();
      if (k.isNotEmpty) headersMap[k] = v;
    }

    // Build auth map
    Map<String, dynamic>? auth;
    switch (_authType) {
      case 'bearer':
        final token = _bearerTokenController.text.trim();
        if (token.isNotEmpty) {
          auth = {'type': 'bearer', 'token': token};
        }
      case 'basic':
        final user = _basicUserController.text.trim();
        final pass = _basicPassController.text.trim();
        if (user.isNotEmpty) {
          auth = {'type': 'basic', 'username': user, 'password': pass};
        }
      case 'api_key':
        final name = _apiKeyNameController.text.trim();
        final value = _apiKeyValueController.text.trim();
        if (name.isNotEmpty) {
          auth = {'type': 'api_key', 'name': name, 'value': value};
        }
    }

    final bodyText = _bodyController.text.trim();

    return RequestBuilderData(
      method: _method,
      url: _urlController.text.trim(),
      headers: headersMap.isEmpty ? null : headersMap,
      body: bodyText.isEmpty ? null : bodyText,
      bodyType: bodyText.isEmpty ? null : _bodyType,
      auth: auth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return Column(
      children: [
        // ── Method + URL + Send row ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              // Method dropdown
              Container(
                decoration: BoxDecoration(
                  color: tokens.bgAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.borderFaint, width: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _method,
                    dropdownColor: tokens.bgAlt,
                    style: TextStyle(
                      color: methodColor(_method),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: tokens.fgMuted,
                      size: 20,
                    ),
                    items: _kMethods.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(
                          m,
                          style: TextStyle(
                            color: methodColor(m),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _method = v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // URL text field
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: TextStyle(color: tokens.fgBright, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'https://api.example.com/endpoint',
                    hintStyle: TextStyle(
                      color: tokens.fgDim.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: tokens.bgAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: tokens.borderFaint,
                        width: 0.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: tokens.borderFaint,
                        width: 0.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: tokens.accent, width: 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send button
              SizedBox(
                height: 40,
                child: FilledButton.icon(
                  onPressed: widget.isSending
                      ? null
                      : () => widget.onSend(_collectData()),
                  icon: widget.isSending
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: tokens.isLight ? Colors.white : tokens.bg,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          size: 16,
                          color: tokens.isLight ? Colors.white : tokens.bg,
                        ),
                  label: Text(
                    'Send',
                    style: TextStyle(
                      color: tokens.isLight ? Colors.white : tokens.bg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Tab bar ────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: tokens.borderFaint, width: 0.5),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: tokens.accent,
            unselectedLabelColor: tokens.fgMuted,
            indicatorColor: tokens.accent,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Params'),
              Tab(text: 'Headers'),
              Tab(text: 'Body'),
              Tab(text: 'Auth'),
            ],
          ),
        ),

        // ── Tab views ──────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildParamsTab(tokens),
              _buildHeadersTab(tokens),
              _buildBodyTab(tokens),
              _buildAuthTab(tokens),
            ],
          ),
        ),
      ],
    );
  }

  // ── Params tab ────────────────────────────────────────────────────────────

  Widget _buildParamsTab(OrchestraColorTokens tokens) {
    // Parse query params from URL and display as read-only info.
    final uri = Uri.tryParse(_urlController.text.trim());
    final params = uri?.queryParameters ?? {};

    return Padding(
      padding: const EdgeInsets.all(16),
      child: params.isEmpty
          ? Center(
              child: Text(
                'Query parameters will be extracted from the URL.\nAdd ?key=value to the URL above.',
                style: TextStyle(color: tokens.fgMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            )
          : ListView(
              children: params.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          e.key,
                          style: TextStyle(
                            color: tokens.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '=',
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            color: tokens.fgBright,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ── Headers tab ───────────────────────────────────────────────────────────

  Widget _buildHeadersTab(OrchestraColorTokens tokens) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _headers.length,
              itemBuilder: (context, index) {
                final entry = _headers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InputField(
                          controller: entry.keyController,
                          hint: 'Header name',
                          tokens: tokens,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InputField(
                          controller: entry.valueController,
                          hint: 'Value',
                          tokens: tokens,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline_rounded,
                          color: tokens.fgDim,
                          size: 18,
                        ),
                        onPressed: _headers.length > 1
                            ? () {
                                setState(() {
                                  _headers[index].dispose();
                                  _headers.removeAt(index);
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _headers.add(_HeaderEntry())),
              icon: Icon(Icons.add_rounded, size: 16, color: tokens.accent),
              label: Text(
                'Add Header',
                style: TextStyle(color: tokens.accent, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body tab ──────────────────────────────────────────────────────────────

  Widget _buildBodyTab(OrchestraColorTokens tokens) {
    const bodyTypes = ['json', 'xml', 'form', 'text'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Body type selector
          Wrap(
            spacing: 8,
            children: bodyTypes.map((t) {
              final isActive = _bodyType == t;
              return ChoiceChip(
                label: Text(
                  t.toUpperCase(),
                  style: TextStyle(
                    color: isActive ? Colors.white : tokens.fgMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: isActive,
                selectedColor: tokens.accent,
                backgroundColor: tokens.bgAlt,
                side: BorderSide(
                  color: isActive ? tokens.accent : tokens.borderFaint,
                  width: 0.5,
                ),
                onSelected: (_) => setState(() => _bodyType = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Body text editor
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.borderFaint, width: 0.5),
              ),
              child: TextField(
                controller: _bodyController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 13,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: _bodyType == 'json'
                      ? '{\n  "key": "value"\n}'
                      : 'Enter request body...',
                  hintStyle: TextStyle(
                    color: tokens.fgDim.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Format JSON button
          if (_bodyType == 'json')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _formatJson,
                  icon: Icon(
                    Icons.auto_fix_high,
                    size: 14,
                    color: tokens.accent,
                  ),
                  label: Text(
                    'Format JSON',
                    style: TextStyle(color: tokens.accent, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _formatJson() {
    try {
      final decoded = jsonDecode(_bodyController.text);
      final formatted = const JsonEncoder.withIndent('  ').convert(decoded);
      setState(() => _bodyController.text = formatted);
    } catch (_) {
      // Not valid JSON — ignore.
    }
  }

  // ── Auth tab ──────────────────────────────────────────────────────────────

  Widget _buildAuthTab(OrchestraColorTokens tokens) {
    const authTypes = ['none', 'bearer', 'basic', 'api_key'];
    final labels = {
      'none': 'None',
      'bearer': 'Bearer Token',
      'basic': 'Basic Auth',
      'api_key': 'API Key',
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auth type dropdown
          Container(
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.borderFaint, width: 0.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _authType,
                isExpanded: true,
                dropdownColor: tokens.bgAlt,
                style: TextStyle(color: tokens.fgBright, fontSize: 14),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: tokens.fgMuted,
                  size: 20,
                ),
                items: authTypes.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(
                      labels[t] ?? t,
                      style: TextStyle(color: tokens.fgBright, fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _authType = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Auth-specific fields
          ..._buildAuthFields(tokens),
        ],
      ),
    );
  }

  List<Widget> _buildAuthFields(OrchestraColorTokens tokens) {
    switch (_authType) {
      case 'bearer':
        return [
          Text(
            'Token',
            style: TextStyle(
              color: tokens.fgMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _InputField(
            controller: _bearerTokenController,
            hint: 'Enter bearer token',
            tokens: tokens,
            obscure: true,
          ),
        ];
      case 'basic':
        return [
          Text(
            'Username',
            style: TextStyle(
              color: tokens.fgMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _InputField(
            controller: _basicUserController,
            hint: 'Username',
            tokens: tokens,
          ),
          const SizedBox(height: 12),
          Text(
            'Password',
            style: TextStyle(
              color: tokens.fgMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _InputField(
            controller: _basicPassController,
            hint: 'Password',
            tokens: tokens,
            obscure: true,
          ),
        ];
      case 'api_key':
        return [
          Text(
            'Header Name',
            style: TextStyle(
              color: tokens.fgMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _InputField(
            controller: _apiKeyNameController,
            hint: 'X-API-Key',
            tokens: tokens,
          ),
          const SizedBox(height: 12),
          Text(
            'Value',
            style: TextStyle(
              color: tokens.fgMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _InputField(
            controller: _apiKeyValueController,
            hint: 'Enter API key value',
            tokens: tokens,
            obscure: true,
          ),
        ];
      default:
        return [
          Text(
            'No authentication configured for this request.',
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
        ];
    }
  }
}

// ── Shared input field ────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.tokens,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String hint;
  final OrchestraColorTokens tokens;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: tokens.fgBright, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: tokens.fgDim.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: tokens.bgAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: tokens.borderFaint, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: tokens.borderFaint, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: tokens.accent, width: 1),
        ),
      ),
    );
  }
}
