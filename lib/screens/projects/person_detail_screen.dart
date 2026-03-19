import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

class PersonDetailScreen extends ConsumerStatefulWidget {
  const PersonDetailScreen({
    super.key,
    required this.projectId,
    required this.personId,
  });

  final String projectId;
  final String personId;

  @override
  ConsumerState<PersonDetailScreen> createState() =>
      _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> {
  Map<String, dynamic>? _person;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final person =
          await ref.read(apiClientProvider).getPerson(widget.personId);
      if (mounted) {
        setState(() {
          _person = person.isEmpty ? null : person;
          _loading = false;
          if (person.isEmpty) _error = 'not_found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: tokens.accent))
            : _error != null
                ? _ErrorBody(tokens: tokens, message: _error!)
                : _PersonContent(
                    person: _person!,
                    projectId: widget.projectId,
                    tokens: tokens,
                  ),
      ),
    );
  }
}

class _PersonContent extends StatelessWidget {
  const _PersonContent({
    required this.person,
    required this.projectId,
    required this.tokens,
  });

  final Map<String, dynamic> person;
  final String projectId;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final name = person['name']?.toString() ?? '';
    final role = person['role']?.toString() ?? '';
    final email = person['email']?.toString() ?? '';
    final githubEmail = person['github_email']?.toString() ?? '';
    final bio = person['bio']?.toString() ?? '';
    final timezone = person['timezone']?.toString() ?? '';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.go(Routes.project(projectId));
                        }
                      },
                      child: Icon(Icons.arrow_back_rounded,
                          color: tokens.fgBright, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context).person,
                      style: TextStyle(
                        color: tokens.fgMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: tokens.accent.withValues(alpha: 0.2),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: tokens.accent,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                if (role.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      role,
                      style: TextStyle(color: tokens.accent, fontSize: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).details,
                      style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (email.isNotEmpty)
                    _Row(label: AppLocalizations.of(context).email, value: email, tokens: tokens),
                  if (githubEmail.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _Row(
                        label: AppLocalizations.of(context).github,
                        value: githubEmail,
                        tokens: tokens),
                  ],
                  if (timezone.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _Row(
                        label: AppLocalizations.of(context).timezone,
                        value: timezone,
                        tokens: tokens),
                  ],
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context).bio,
                        style:
                            TextStyle(color: tokens.fgMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(bio,
                        style: TextStyle(
                            color: tokens.fgBright,
                            fontSize: 14,
                            height: 1.5)),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.tokens,
  });

  final String label;
  final String value;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(color: tokens.fgMuted, fontSize: 13)),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.tokens, required this.message});
  final OrchestraColorTokens tokens;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).failedToLoad,
                style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(color: tokens.fgMuted, fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
