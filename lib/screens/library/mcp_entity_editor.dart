import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/api/library_provider.dart';
import 'package:orchestra/core/providers/admin_settings_provider.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/widgets/markdown/markdown_renderer.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

// -- Localized entity label resolver ------------------------------------------

String _localizedEntityLabel(AppLocalizations l10n, McpEntityType type) =>
    switch (type) {
      McpEntityType.agent => l10n.agent,
      McpEntityType.skill => l10n.skill,
      McpEntityType.workflow => l10n.workflow,
      McpEntityType.doc => l10n.doc,
      McpEntityType.feature => l10n.feature,
      McpEntityType.plan => l10n.plan,
      McpEntityType.request => l10n.request,
      McpEntityType.person => l10n.person,
    };

// -- Entity type definition ---------------------------------------------------

/// Defines which entity type we're editing and how to map UI fields to API.
enum McpEntityType {
  agent,
  skill,
  workflow,
  doc,
  feature,
  plan,
  request,
  person,
}

class _EntityMeta {
  const _EntityMeta({
    required this.label,
    required this.icon,
    required this.color,
    required this.listRoute,
    required this.fields,
    this.hasBody = false,
    this.bodyKey,
    this.smartHint,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String listRoute;
  final List<_FieldDef> fields;
  final bool hasBody;

  /// The JSON key used for the body/content field in API calls.
  final String? bodyKey;

  /// Placeholder hint for the smart action prompt input.
  final String? smartHint;

  static _EntityMeta of(McpEntityType type) => switch (type) {
        McpEntityType.agent => _EntityMeta(
            label: 'Agent',
            icon: Icons.smart_toy_rounded,
            color: const Color(0xFFA78BFA),
            listRoute: Routes.agents,
            hasBody: true,
            bodyKey: 'system_prompt',
            smartHint:
                'e.g. Create an agent that handles code reviews for Go projects',
            fields: [
              const _FieldDef('name', 'Name', required: true),
              const _FieldDef('description', 'Description'),
              const _FieldDef('model', 'Model'),
            ],
          ),
        McpEntityType.skill => _EntityMeta(
            label: 'Skill',
            icon: Icons.bolt_rounded,
            color: const Color(0xFFF97316),
            listRoute: Routes.skills,
            hasBody: true,
            bodyKey: 'description',
            smartHint:
                'e.g. Create a skill that generates API docs from OpenAPI specs',
            fields: [
              const _FieldDef('name', 'Name', required: true),
              const _FieldDef('command', 'Command (e.g. /my-skill)'),
              const _FieldDef('description', 'Description'),
            ],
          ),
        McpEntityType.workflow => _EntityMeta(
            label: 'Workflow',
            icon: Icons.account_tree_rounded,
            color: const Color(0xFFEC4899),
            listRoute: Routes.workflows,
            hasBody: false,
            smartHint:
                'e.g. Create a scrum workflow with backlog, sprint, review, and done states',
            fields: [
              const _FieldDef('name', 'Name', required: true),
              const _FieldDef('description', 'Description'),
              const _FieldDef('initial_state', 'Initial State'),
            ],
          ),
        McpEntityType.doc => _EntityMeta(
            label: 'Doc',
            icon: Icons.description_rounded,
            color: const Color(0xFF60A5FA),
            listRoute: Routes.docs,
            hasBody: true,
            bodyKey: 'content',
            smartHint:
                'e.g. Write a getting started guide for new contributors',
            fields: [
              const _FieldDef('title', 'Title', required: true),
              const _FieldDef('path', 'Path (e.g. docs/my-doc.md)'),
            ],
          ),
        McpEntityType.feature => _EntityMeta(
            label: 'Feature',
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFF00E5FF),
            listRoute: Routes.projects,
            hasBody: true,
            bodyKey: 'description',
            smartHint: 'e.g. Add dark mode support to the settings page',
            fields: [
              const _FieldDef('title', 'Title', required: true),
              const _FieldDef('description', 'Description'),
              const _FieldDef('kind', 'Kind',
                  options: ['feature', 'bug', 'hotfix', 'chore']),
              const _FieldDef('priority', 'Priority',
                  options: ['P0', 'P1', 'P2', 'P3']),
              const _FieldDef('project_id', 'Project ID', required: true),
            ],
          ),
        McpEntityType.plan => _EntityMeta(
            label: 'Plan',
            icon: Icons.map_rounded,
            color: const Color(0xFF4ADE80),
            listRoute: Routes.projects,
            hasBody: true,
            bodyKey: 'description',
            smartHint:
                'e.g. Plan the migration from REST to GraphQL in 3 phases',
            fields: [
              const _FieldDef('title', 'Title', required: true),
              const _FieldDef('description', 'Description'),
              const _FieldDef('project_id', 'Project ID', required: true),
            ],
          ),
        McpEntityType.request => _EntityMeta(
            label: 'Request',
            icon: Icons.inbox_rounded,
            color: const Color(0xFFFBBF24),
            listRoute: Routes.projects,
            hasBody: true,
            bodyKey: 'description',
            smartHint:
                'e.g. Request a bulk export feature for the admin dashboard',
            fields: [
              const _FieldDef('title', 'Title', required: true),
              const _FieldDef('description', 'Description'),
              const _FieldDef('kind', 'Kind',
                  options: ['feature', 'bug', 'hotfix']),
              const _FieldDef('priority', 'Priority',
                  options: ['P0', 'P1', 'P2', 'P3']),
            ],
          ),
        McpEntityType.person => _EntityMeta(
            label: 'Person',
            icon: Icons.person_rounded,
            color: const Color(0xFF818CF8),
            listRoute: Routes.projects,
            smartHint:
                'e.g. Add a team member named Sarah, senior engineer, Pacific timezone',
            fields: [
              const _FieldDef('name', 'Name', required: true),
              const _FieldDef('role', 'Role'),
              const _FieldDef('email', 'Email'),
              const _FieldDef('github_email', 'GitHub Email'),
              const _FieldDef('bio', 'Bio'),
              const _FieldDef('timezone', 'Timezone'),
            ],
          ),
      };
}

class _FieldDef {
  const _FieldDef(
    this.key,
    this.label, {
    this.required = false,
    this.options,
  });

  final String key;
  final String label;
  final bool required;
  final List<String>? options;
}

// -- Editor screen ------------------------------------------------------------

/// Generic editor screen for creating/editing any MCP-backed entity.
///
/// Pass [entityId] = null for "create new", or a real ID to edit existing.
class McpEntityEditorScreen extends ConsumerStatefulWidget {
  const McpEntityEditorScreen({
    super.key,
    required this.entityType,
    this.entityId,
    this.projectId,
    this.initialData,
  });

  final McpEntityType entityType;
  final String? entityId;
  final String? projectId;
  final Map<String, dynamic>? initialData;

  bool get isNew => entityId == null;

  @override
  ConsumerState<McpEntityEditorScreen> createState() =>
      _McpEntityEditorScreenState();
}

class _McpEntityEditorScreenState
    extends ConsumerState<McpEntityEditorScreen> {
  late final _EntityMeta _meta;
  final Map<String, TextEditingController> _controllers = {};
  final _bodyController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _preview = false;

  // ── Smart action state ──────────────────────────────────────────────────
  bool _smartMode = false; // set true in initState if new + desktop
  bool _generating = false;
  String _selectedModel = 'sonnet';
  final _promptController = TextEditingController();
  final List<_SmartEvent> _smartEvents = [];

  // ── Workflow-specific JSON data (states, transitions, gates) ───────────
  Map<String, dynamic>? _workflowStates;
  List<dynamic>? _workflowTransitions;
  Map<String, dynamic>? _workflowGates;

  // ── Admin-managed prompt (loaded from smart_prompts setting) ──────────
  String? _adminPrompt;

  @override
  void initState() {
    super.initState();
    _meta = _EntityMeta.of(widget.entityType);

    // Create controllers for each field
    for (final field in _meta.fields) {
      _controllers[field.key] = TextEditingController();
    }

    if (widget.isNew) {
      _loading = false;
      // Default to smart mode on desktop when MCP is available
      _smartMode = isDesktop;
      // Pre-fill project_id if provided
      if (widget.projectId != null) {
        _controllers['project_id']?.text = widget.projectId!;
      }
      // Pre-fill from initialData
      if (widget.initialData != null) {
        for (final entry in widget.initialData!.entries) {
          _controllers[entry.key]?.text = entry.value?.toString() ?? '';
        }
      }
    } else {
      _loadEntity();
    }

    // Load admin-managed smart action prompt for this entity type
    _loadAdminPrompt();
  }

  Future<void> _loadAdminPrompt() async {
    try {
      final data =
          await ref.read(adminSettingProvider('smart_prompts').future);
      final prompts = data['prompts'];
      if (prompts is List) {
        final key = widget.entityType.name; // agent, skill, workflow, etc.
        for (final p in prompts) {
          if (p is Map<String, dynamic> && p['key'] == key) {
            final prompt = p['prompt'] as String?;
            if (prompt != null && prompt.isNotEmpty) {
              _adminPrompt = prompt;
            }
            break;
          }
        }
      }
    } catch (_) {
      // Admin prompt not available — will fall back to hardcoded default
    }
  }

  Future<void> _loadEntity() async {
    try {
      final client = ref.read(apiClientProvider);
      final data = await switch (widget.entityType) {
        McpEntityType.agent => client.getAgent(widget.entityId!),
        McpEntityType.skill => client.getSkill(widget.entityId!),
        McpEntityType.workflow => client.getWorkflow(widget.entityId!),
        McpEntityType.doc => client.getDoc(widget.entityId!),
        McpEntityType.feature => client.getFeature(widget.entityId!),
        McpEntityType.plan =>
          client.getPlan(widget.projectId ?? '', widget.entityId!),
        McpEntityType.request => client.getRequest(widget.entityId!),
        McpEntityType.person => client.getPerson(widget.entityId!),
      };
      if (mounted) {
        setState(() {
          for (final field in _meta.fields) {
            _controllers[field.key]?.text =
                data[field.key]?.toString() ?? '';
          }
          // Load body/content
          final body = data['body'] ??
              data['content'] ??
              data['system_prompt'] ??
              data['systemPrompt'] ??
              data['description'] ??
              '';
          _bodyController.text = body.toString();

          // Load workflow-specific JSON fields
          if (widget.entityType == McpEntityType.workflow) {
            if (data['states'] is Map) {
              _workflowStates =
                  Map<String, dynamic>.from(data['states'] as Map);
            }
            if (data['transitions'] is List) {
              _workflowTransitions = data['transitions'] as List<dynamic>;
            }
            if (data['gates'] is Map) {
              _workflowGates =
                  Map<String, dynamic>.from(data['gates'] as Map);
            }
          }

          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToLoad}: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _bodyController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Validate required fields
    for (final field in _meta.fields) {
      if (field.required && (_controllers[field.key]?.text.trim().isEmpty ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).fieldIsRequired(field.label))),
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final client = ref.read(apiClientProvider);
      final body = <String, dynamic>{};

      for (final field in _meta.fields) {
        final value = _controllers[field.key]?.text.trim() ?? '';
        if (value.isNotEmpty) {
          body[field.key] = value;
        }
      }

      // Add body/content if applicable
      if (_meta.hasBody) {
        final bodyText = _bodyController.text;
        switch (widget.entityType) {
          case McpEntityType.agent:
            body['system_prompt'] = bodyText;
          case McpEntityType.doc:
            body['content'] = bodyText;
          case McpEntityType.feature:
          case McpEntityType.plan:
          case McpEntityType.request:
            body['description'] = bodyText;
          case McpEntityType.skill:
            body['description'] = bodyText;
          case McpEntityType.workflow:
            body['description'] = bodyText;
          case McpEntityType.person:
            break;
        }
      }

      // Include workflow-specific JSON data
      if (widget.entityType == McpEntityType.workflow) {
        if (_workflowStates != null) body['states'] = _workflowStates;
        if (_workflowTransitions != null) body['transitions'] = _workflowTransitions;
        if (_workflowGates != null) body['gates'] = _workflowGates;
      }

      if (widget.isNew) {
        await switch (widget.entityType) {
          McpEntityType.agent => client.createAgent(body),
          McpEntityType.skill => client.createSkill(body),
          McpEntityType.workflow => client.createWorkflow(body),
          McpEntityType.doc => client.createDoc(body),
          McpEntityType.feature => client.createFeature(body),
          McpEntityType.plan => client.createPlan(body),
          McpEntityType.request => client.createRequest(body),
          McpEntityType.person => client.createPerson(body),
        };
      } else {
        await switch (widget.entityType) {
          McpEntityType.agent =>
            client.updateAgent(widget.entityId!, body),
          McpEntityType.skill =>
            client.updateSkill(widget.entityId!, body),
          McpEntityType.workflow =>
            client.updateWorkflow(widget.entityId!, body),
          McpEntityType.doc =>
            client.updateDoc(widget.entityId!, body),
          McpEntityType.feature =>
            client.updateFeature(widget.entityId!, body),
          McpEntityType.plan =>
            client.updatePlan(widget.entityId!, body),
          McpEntityType.request =>
            client.updateRequest(widget.entityId!, body),
          McpEntityType.person =>
            client.updatePerson(widget.entityId!, body),
        };
      }

      // Invalidate the relevant list provider so data refreshes
      _invalidateProvider();

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final entityLabel = _localizedEntityLabel(l10n, widget.entityType);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isNew
                  ? l10n.entityCreated(entityLabel)
                  : l10n.entitySaved(entityLabel))),
        );
        // Navigate back
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          context.go(_meta.listRoute);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToSave}: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  void _invalidateProvider() {
    switch (widget.entityType) {
      case McpEntityType.agent:
        ref.invalidate(agentsProvider);
      case McpEntityType.skill:
        ref.invalidate(skillsProvider);
      case McpEntityType.workflow:
        ref.invalidate(workflowsProvider);
      case McpEntityType.doc:
        ref.invalidate(docsProvider);
      case McpEntityType.feature:
      case McpEntityType.plan:
      case McpEntityType.request:
      case McpEntityType.person:
        // These are project-scoped — can't easily invalidate here but
        // the FutureBuilder in the project detail will re-fetch on rebuild.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: tokens.bg,
        body: Center(child: CircularProgressIndicator(color: tokens.accent)),
      );
    }

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildToolbar(tokens),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Type badge
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _meta.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _meta.color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_meta.icon, color: _meta.color, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              widget.isNew
                                  ? AppLocalizations.of(context).newEntityTitle(_meta.label)
                                  : AppLocalizations.of(context).editEntityTitle(_meta.label),
                              style: TextStyle(
                                color: _meta.color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mode toggle (new entities on desktop only)
                    if (widget.isNew && isDesktop) ...[
                      _buildModeToggle(tokens),
                      const SizedBox(height: 16),
                    ],

                    // Smart Action panel OR manual form
                    if (_smartMode && widget.isNew)
                      _buildSmartActionPanel(tokens)
                    else ...[
                      // Dynamic fields
                      for (final field in _meta.fields) ...[
                        _buildField(tokens, field),
                        const SizedBox(height: 12),
                      ],

                      // Body/content area
                      if (_meta.hasBody) ...[
                        const SizedBox(height: 4),
                        Divider(color: tokens.border, height: 1),
                        const SizedBox(height: 16),
                        if (_preview)
                          _buildPreview(tokens)
                        else
                          _buildBodyEditor(tokens),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(OrchestraColorTokens tokens, _FieldDef field) {
    // Dropdown for fields with options
    if (field.options != null) {
      final current = _controllers[field.key]?.text ?? '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: TextStyle(
              color: tokens.fgMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: field.options!.contains(current) ? current : null,
            items: field.options!
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) {
              if (v != null) _controllers[field.key]?.text = v;
            },
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).selectFieldHint(field.label.toLowerCase()),
              hintStyle: TextStyle(color: tokens.fgDim, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: tokens.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: tokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: tokens.accent),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            dropdownColor: tokens.bgAlt,
            style: TextStyle(color: tokens.fgBright, fontSize: 14),
          ),
        ],
      );
    }

    // Regular text field
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.label}${field.required ? ' *' : ''}',
          style: TextStyle(
            color: tokens.fgMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _controllers[field.key],
          style: TextStyle(color: tokens.fgBright, fontSize: 14),
          decoration: InputDecoration(
            hintText: field.label,
            hintStyle: TextStyle(color: tokens.fgDim, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: tokens.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: tokens.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: tokens.accent),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(OrchestraColorTokens tokens) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: tokens.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Back / Cancel
          TextButton.icon(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go(_meta.listRoute);
              }
            },
            icon: Icon(Icons.arrow_back_rounded,
                size: 18, color: tokens.fgMuted),
            label: Text(
              AppLocalizations.of(context).cancel,
              style: TextStyle(color: tokens.fgMuted, fontSize: 13),
            ),
          ),

          const Spacer(),

          // Preview toggle (only if has body)
          if (_meta.hasBody)
            IconButton(
              onPressed: () => setState(() => _preview = !_preview),
              icon: Icon(
                _preview ? Icons.edit_rounded : Icons.visibility_rounded,
                size: 18,
                color: tokens.fgMuted,
              ),
              tooltip: _preview ? AppLocalizations.of(context).edit : AppLocalizations.of(context).preview,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),

          const SizedBox(width: 8),

          // Save button
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.isLight ? Colors.white : Colors.black,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 16),
            label: Text(widget.isNew ? AppLocalizations.of(context).create : AppLocalizations.of(context).save),
            style: FilledButton.styleFrom(
              backgroundColor: _meta.color,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              minimumSize: const Size(0, 34),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyEditor(OrchestraColorTokens tokens) {
    final l10n = AppLocalizations.of(context);
    final hint = switch (widget.entityType) {
      McpEntityType.agent => l10n.systemPromptHint,
      McpEntityType.doc => l10n.docContentHint,
      _ => l10n.descriptionMarkdownHint,
    };

    return TextField(
      controller: _bodyController,
      style: TextStyle(
        color: tokens.fgBright,
        fontSize: 14,
        height: 1.7,
        fontFamily: 'monospace',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: tokens.fgDim,
          fontSize: 14,
          fontFamily: 'monospace',
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: null,
      minLines: 15,
      keyboardType: TextInputType.multiline,
    );
  }

  Widget _buildPreview(OrchestraColorTokens tokens) {
    final text = _bodyController.text;
    if (text.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Text(
            AppLocalizations.of(context).nothingToPreview,
            style: TextStyle(color: tokens.fgDim, fontSize: 14),
          ),
        ),
      );
    }

    return MarkdownRendererWidget(
      content: text,
    );
  }

  // ── Smart Action ────────────────────────────────────────────────────────

  Widget _buildModeToggle(OrchestraColorTokens tokens) {
    return Row(
      children: [
        _SmartModeChip(
          label: AppLocalizations.of(context).smartAction,
          icon: Icons.auto_awesome_rounded,
          isActive: _smartMode,
          activeColor: _meta.color,
          tokens: tokens,
          onTap: () => setState(() => _smartMode = true),
        ),
        const SizedBox(width: 8),
        _SmartModeChip(
          label: AppLocalizations.of(context).manual,
          icon: Icons.edit_rounded,
          isActive: !_smartMode,
          activeColor: tokens.fgMuted,
          tokens: tokens,
          onTap: () => setState(() => _smartMode = false),
        ),
      ],
    );
  }

  Widget _buildSmartActionPanel(OrchestraColorTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Prompt input card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _meta.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _meta.color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 18, color: _meta.color),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).editorDescribeWhatYouWant,
                    style: TextStyle(
                      color: _meta.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _promptController,
                maxLines: 3,
                autofocus: true,
                enabled: !_generating,
                style: TextStyle(color: tokens.fgBright, fontSize: 14),
                decoration: InputDecoration(
                  hintText: _meta.smartHint ?? AppLocalizations.of(context).describeWhatYouWant,
                  hintStyle: TextStyle(
                    color: tokens.fgDim.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: tokens.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: tokens.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: tokens.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _meta.color),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: tokens.borderFaint),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onSubmitted: _generating ? null : (_) => _generate(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final m in const ['haiku', 'sonnet', 'opus'])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _ModelChip(
                        label: m[0].toUpperCase() + m.substring(1),
                        isActive: _selectedModel == m,
                        activeColor: _meta.color,
                        tokens: tokens,
                        onTap: _generating
                            ? null
                            : () => setState(() => _selectedModel = m),
                      ),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _generating ? null : _generate,
                    icon: _generating
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  tokens.isLight ? Colors.white : Colors.black,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(_generating ? AppLocalizations.of(context).generating : AppLocalizations.of(context).generate),
                    style: FilledButton.styleFrom(
                      backgroundColor: _meta.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      minimumSize: const Size(0, 34),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Event log
        if (_smartEvents.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.borderFaint),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final event in _smartEvents)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          event.isError
                              ? Icons.error_outline_rounded
                              : event.isDone
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.circle_outlined,
                          size: 14,
                          color: event.isError
                              ? const Color(0xFFEF4444)
                              : event.isDone
                                  ? const Color(0xFF22C55E)
                                  : tokens.fgDim,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.message,
                            style: TextStyle(
                              color: event.isError
                                  ? const Color(0xFFEF4444)
                                  : tokens.fgMuted,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Loading shimmer while generating
                if (_generating)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Shimmer.fromColors(
                      baseColor: tokens.bgAlt,
                      highlightColor: tokens.border,
                      child: Container(
                        height: 14,
                        width: 160,
                        decoration: BoxDecoration(
                          color: tokens.bgAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _addEvent(String message, {bool isError = false, bool isDone = false}) {
    setState(() {
      _smartEvents.add(_SmartEvent(message, isError: isError, isDone: isDone));
    });
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final mcp = ref.read(mcpClientProvider);
    if (mcp == null) {
      _addEvent('MCP client not available (desktop only)', isError: true);
      return;
    }

    setState(() {
      _generating = true;
      _smartEvents.clear();
    });

    final l10n = AppLocalizations.of(context);
    final entityLabel = _localizedEntityLabel(l10n, widget.entityType);
    _addEvent(l10n.sendingPromptToAi);

    try {
      final systemPrompt = _buildSystemPrompt();
      _addEvent(l10n.aiGeneratingEntity(entityLabel));

      final result = await mcp.callTool(
        'ai_prompt',
        {
          'prompt': prompt,
          'system_prompt': systemPrompt,
          'wait': true,
          'model': _selectedModel,
          'permission_mode': 'bypassPermissions',
          'max_budget': 0.05,
        },
        timeout: const Duration(seconds: 300),
      );

      _addEvent(l10n.responseReceivedParsing);

      // Check for tool-level error
      if (result['isError'] == true) {
        final c = result['content'];
        final errText = (c is List && c.isNotEmpty && c[0] is Map)
            ? c[0]['text']?.toString() ?? 'Unknown error'
            : 'Unknown error';
        _addEvent('AI error: $errText', isError: true);
        setState(() => _generating = false);
        return;
      }

      final parsed = _unwrapAndParse(result);
      if (parsed == null) {
        _addEvent(l10n.failedToParseAiResponse, isError: true);
        setState(() => _generating = false);
        return;
      }

      // Populate form fields
      for (final field in _meta.fields) {
        final value = parsed[field.key]?.toString();
        if (value != null && value.isNotEmpty) {
          _controllers[field.key]?.text = value;
        }
      }

      // Populate body
      if (_meta.hasBody && _meta.bodyKey != null) {
        final bodyText = parsed[_meta.bodyKey]?.toString() ?? '';
        if (bodyText.isNotEmpty) {
          _bodyController.text = bodyText;
        }
      }

      // Store workflow-specific JSON data (states, transitions, gates)
      if (widget.entityType == McpEntityType.workflow) {
        if (parsed['states'] is Map) {
          _workflowStates = parsed['states'] as Map<String, dynamic>;
        }
        if (parsed['transitions'] is List) {
          _workflowTransitions = parsed['transitions'] as List<dynamic>;
        }
        if (parsed['gates'] is Map) {
          _workflowGates = parsed['gates'] as Map<String, dynamic>;
        }
      }

      _addEvent(
        l10n.entityGeneratedSuccessfully(entityLabel),
        isDone: true,
      );

      // Switch to manual mode for review
      setState(() {
        _generating = false;
        _smartMode = false;
      });
    } catch (e) {
      _addEvent('Error: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true);
      setState(() => _generating = false);
    }
  }

  String _buildSystemPrompt() {
    // Use admin-managed prompt if available
    if (_adminPrompt != null) return _adminPrompt!;

    // Workflow gets a specialized prompt with states/transitions/gates
    if (widget.entityType == McpEntityType.workflow) {
      return 'You are creating an Orchestra Workflow definition. '
          'Output ONLY a valid JSON object with these fields:\n'
          '{\n'
          '  "name": string (required, workflow name),\n'
          '  "description": string (brief description),\n'
          '  "initial_state": string (the starting state key),\n'
          '  "states": { "<key>": {"label": string, "terminal": bool, "active_work": bool} },\n'
          '  "transitions": [{"from": "<state_key>", "to": "<state_key>", "gate": "<gate_key or empty>"}],\n'
          '  "gates": { "<key>": {"label": string, "required_section": string, "skippable_for": []} }\n'
          '}\n\n'
          'Example state keys: "todo", "in-progress", "in-review", "done".\n'
          'terminal=true means the workflow ends at that state.\n'
          'active_work=true means active development happens in that state.\n\n'
          'Rules:\n'
          '- Output ONLY the raw JSON object. No markdown code fences. No explanation.\n'
          '- states, transitions, and gates must be proper JSON (not strings).\n'
          '- Every state referenced in transitions must exist in states.\n'
          '- initial_state must be a valid state key.';
    }

    final fields = <String>[];
    for (final field in _meta.fields) {
      var desc = '"${field.key}": string';
      if (field.options != null) {
        desc += ' (one of: ${field.options!.join(", ")})';
      }
      if (field.required) desc += ' (required)';
      fields.add(desc);
    }

    if (_meta.hasBody && _meta.bodyKey != null) {
      fields.add('"${_meta.bodyKey}": string (detailed markdown content)');
    }

    return 'You are creating an Orchestra ${_meta.label}. '
        'Output ONLY a valid JSON object with these fields:\n'
        '{${fields.join(', ')}}\n\n'
        'Rules:\n'
        '- Output ONLY the raw JSON object. No markdown code fences. No explanation.\n'
        '- All values must be strings.\n'
        '- For the markdown content field, use proper markdown formatting.';
  }

  Map<String, dynamic>? _unwrapAndParse(Map<String, dynamic> result) {
    // Extract text from MCP content envelope
    String? text;
    final content = result['content'];
    if (content is List && content.isNotEmpty) {
      final first = content[0];
      if (first is Map && first['type'] == 'text') {
        text = first['text'] as String?;
      }
    }
    text ??= result['response'] as String? ?? result['text'] as String?;
    if (text == null || text.isEmpty) return null;

    text = text.trim();

    // The bridge returns a JSON envelope: {"response":"...", "session_id":"...", ...}
    // The actual AI output is in the "response" field.
    try {
      final envelope = jsonDecode(text);
      if (envelope is Map<String, dynamic> && envelope.containsKey('response')) {
        text = envelope['response']?.toString() ?? text;
      }
    } catch (_) {
      // Not a bridge envelope — use text as-is
    }

    text = text!.trim();

    // Strip markdown code fences
    if (text.startsWith('```')) {
      final lines = text.split('\n');
      if (lines.length >= 3) {
        lines.removeAt(0);
        if (lines.last.trim() == '```') lines.removeLast();
        text = lines.join('\n').trim();
      }
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Try extracting JSON from text
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start >= 0 && end > start) {
        try {
          final decoded = jsonDecode(text.substring(start, end + 1));
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {}
      }
    }
    return null;
  }
}

// ── Smart Action helpers ──────────────────────────────────────────────────────

class _SmartEvent {
  const _SmartEvent(this.message, {this.isError = false, this.isDone = false});
  final String message;
  final bool isError;
  final bool isDone;
}

class _ModelChip extends StatelessWidget {
  const _ModelChip({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color activeColor;
  final OrchestraColorTokens tokens;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.4)
                : tokens.borderFaint,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : tokens.fgDim,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SmartModeChip extends StatelessWidget {
  const _SmartModeChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.4)
                : tokens.borderFaint,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isActive ? activeColor : tokens.fgDim),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : tokens.fgDim,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
