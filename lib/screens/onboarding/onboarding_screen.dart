import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/screens/onboarding/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Page definitions ──────────────────────────────────────────────────────────

/// Returns the onboarding page data with localized strings.
List<OnboardingPageData> _buildPages(AppLocalizations l10n) => [
  OnboardingPageData(
    title: l10n.onboardingWelcomeTitle,
    subtitle: l10n.onboardingWelcomeSubtitle,
    icon: Icons.music_note_rounded,
    accentOverride: null, // uses default accent from theme
  ),
  OnboardingPageData(
    title: l10n.onboardingFeaturesTitle,
    subtitle: l10n.onboardingFeaturesSubtitle,
    icon: Icons.auto_awesome_rounded,
    accentOverride: const Color(0xFF38BDF8), // teal accent for variety
  ),
  OnboardingPageData(
    title: l10n.onboardingHealthTitle,
    subtitle: l10n.onboardingHealthSubtitle,
    icon: Icons.favorite_rounded,
    accentOverride: const Color(0xFF4ADE80), // green for health
  ),
  OnboardingPageData(
    title: l10n.onboardingGetStartedTitle,
    subtitle: l10n.onboardingGetStartedSubtitle,
    icon: Icons.rocket_launch_rounded,
    accentOverride: null,
  ),
];

/// Total number of onboarding pages (constant, independent of l10n).
const _pageCount = 4;

// ── Screen ────────────────────────────────────────────────────────────────────

/// Multi-step onboarding flow shown to first-time users.
///
/// Four pages cycle through via a [PageView]. Completing the last step writes
/// `onboarding_complete = true` to [SharedPreferences] and navigates to
/// `/login`.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _pageCount - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _animateToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  void _next() {
    if (_isLastPage) {
      _complete();
    } else {
      _animateToPage(_currentPage + 1);
    }
  }

  void _skip() => _complete();

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final pages = _buildPages(l10n);

    return Scaffold(
      backgroundColor: tokens.bg,
      // Skip button in the top-right corner (hidden on the last page).
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isLastPage)
            Semantics(
              label: l10n.onboardingSkipAccessibility,
              child: TextButton(
                onPressed: _skip,
                child: Text(
                  l10n.onboardingSkip,
                  style: TextStyle(color: tokens.fgDim, fontSize: 14),
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Page content ────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return OnboardingPage(data: pages[index]);
                },
              ),
            ),

            // ── Bottom controls ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                children: [
                  _PageIndicator(
                    count: pages.length,
                    current: _currentPage,
                    tokens: tokens,
                  ),
                  const SizedBox(height: 24),
                  _BottomButtons(
                    isLastPage: _isLastPage,
                    tokens: tokens,
                    onNext: _next,
                    onSkip: _skip,
                    currentPage: _currentPage,
                    totalPages: pages.length,
                    onDotTap: _animateToPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page indicator dots ───────────────────────────────────────────────────────

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.current,
    required this.tokens,
  });

  final int count;
  final int current;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: l10n.onboardingPageIndicator(current + 1, count),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isActive = index == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive
                  ? tokens.accent
                  : tokens.fgDim.withValues(alpha: 0.4),
            ),
          );
        }),
      ),
    );
  }
}

// ── Bottom action buttons ─────────────────────────────────────────────────────

class _BottomButtons extends StatelessWidget {
  const _BottomButtons({
    required this.isLastPage,
    required this.tokens,
    required this.onNext,
    required this.onSkip,
    required this.currentPage,
    required this.totalPages,
    required this.onDotTap,
  });

  final bool isLastPage;
  final OrchestraColorTokens tokens;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onDotTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        // Back affordance — hidden on the first page.
        if (currentPage > 0)
          Semantics(
            label: l10n.onboardingPreviousPageAccessibility,
            child: _OutlineButton(
              label: l10n.back,
              tokens: tokens,
              onPressed: () => onDotTap(currentPage - 1),
            ),
          )
        else
          const Spacer(),

        const Spacer(),

        // Primary action — "Next" or "Get Started".
        Semantics(
          label: isLastPage
              ? l10n.onboardingGetStartedAccessibility
              : l10n.onboardingNextPageAccessibility,
          child: _FilledButton(
            label: isLastPage ? l10n.getStarted : l10n.next,
            tokens: tokens,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}

// ── Reusable button components ────────────────────────────────────────────────

class _FilledButton extends StatelessWidget {
  const _FilledButton({
    required this.label,
    required this.tokens,
    required this.onPressed,
  });

  final String label;
  final OrchestraColorTokens tokens;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: tokens.accent,
        foregroundColor: tokens.bg,
        minimumSize: const Size(120, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.tokens,
    required this.onPressed,
  });

  final String label;
  final OrchestraColorTokens tokens;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.fgMuted,
        side: BorderSide(color: tokens.border),
        minimumSize: const Size(100, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Text(label),
    );
  }
}
