import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Report issue form screen -- title, description, category, severity, submit.
class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _category = 'Bug';
  String _severity = 'Medium';
  bool _submitting = false;

  static const _categories = [
    'Bug',
    'Feature Request',
    'Performance',
    'UI/UX',
    'Crash',
    'Other',
  ];

  static const _severities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    // Mock submission delay
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).issueReported),
        backgroundColor: ThemeTokens.of(context).accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: tokens.fgMuted, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          AppLocalizations.of(context).reportIssue,
          style: TextStyle(
            color: tokens.fgBright,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Title ───────────────────────────────────────────────────
            _fieldLabel(tokens, 'Title'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 14),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              decoration: _inputDecoration(tokens, 'Brief description of the issue'),
            ),

            const SizedBox(height: 16),

            // ── Description ─────────────────────────────────────────────
            _fieldLabel(tokens, 'Description'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descriptionCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 14),
              maxLines: 5,
              validator: (v) =>
                  (v == null || v.trim().length < 10) ? 'Please provide more detail' : null,
              decoration: _inputDecoration(tokens, 'Steps to reproduce, expected vs actual behavior...'),
            ),

            const SizedBox(height: 16),

            // ── Category ────────────────────────────────────────────────
            _fieldLabel(tokens, 'Category'),
            const SizedBox(height: 6),
            _buildDropdown<String>(
              tokens: tokens,
              value: _category,
              items: _categories,
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),

            const SizedBox(height: 16),

            // ── Severity ────────────────────────────────────────────────
            _fieldLabel(tokens, 'Severity'),
            const SizedBox(height: 6),
            _buildSeverityPicker(tokens),

            const SizedBox(height: 28),

            // ── Submit ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: tokens.accent.withValues(alpha: 0.5),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(AppLocalizations.of(context).submitIssue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Severity picker (segmented row) ───────────────────────────────────

  Widget _buildSeverityPicker(OrchestraColorTokens tokens) {
    return Row(
      children: _severities.map((s) {
        final isSelected = s == _severity;
        final color = _severityColor(s);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: s == _severities.last ? 0 : 6,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _severity = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : tokens.bgAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? color : tokens.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? color : tokens.fgMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _severityColor(String severity) {
    return switch (severity) {
      'Low' => const Color(0xFF22C55E),
      'Medium' => const Color(0xFFF59E0B),
      'High' => const Color(0xFFF97316),
      'Critical' => const Color(0xFFEF4444),
      _ => const Color(0xFF64748B),
    };
  }

  // ── Shared helpers ────────────────────────────────────────────────────

  Widget _fieldLabel(OrchestraColorTokens tokens, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tokens.fgDim,
          letterSpacing: 0.4,
        ),
      );

  InputDecoration _inputDecoration(OrchestraColorTokens tokens, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: tokens.fgDim),
      filled: true,
      fillColor: tokens.bgAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: tokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: tokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: tokens.accent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required OrchestraColorTokens tokens,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: tokens.bgAlt,
          style: TextStyle(fontSize: 14, color: tokens.fgBright),
          icon: Icon(Icons.expand_more_rounded, color: tokens.fgMuted, size: 20),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(item.toString()),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
