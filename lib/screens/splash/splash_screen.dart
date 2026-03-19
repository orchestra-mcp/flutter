import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/auth/auth_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Splash screen displayed at app launch.
///
/// Plays a 1.5-second fade-in animation on the Orchestra logotype, then
/// inspects [authProvider] state and routes accordingly:
///
/// - [AuthAuthenticated] → `/summary`
/// - [AuthUnauthenticated] + onboarding not complete → `/onboarding`
/// - [AuthUnauthenticated] + onboarding complete     → `/login`
///
/// Navigation is deferred until [authProvider] exits the loading state.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  /// Guard flag — prevents the navigation callback from firing more than once.
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Fade in over the first 60 % of the timeline.
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    // Subtle scale-up over the first 70 % of the timeline.
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Kick off the animation; attempt navigation after it completes.
    _controller.forward().then((_) => _handleNavigation());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Polls until [authProvider] resolves, then navigates to the correct route.
  ///
  /// `AsyncValue.value` returns `null` while the provider is loading or has
  /// an error, and returns the wrapped [AuthState] once resolved.
  Future<void> _handleNavigation() async {
    if (_navigated || !mounted) return;

    // Wait until auth is no longer in the loading/error state.
    AuthState? resolved = ref.read(authProvider).value;
    while (resolved == null) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      resolved = ref.read(authProvider).value;
    }

    if (!mounted) return;
    _navigated = true;

    if (resolved is AuthAuthenticated) {
      context.go('/summary');
      return;
    }

    // AuthUnauthenticated — decide between onboarding and login.
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    if (onboardingComplete) {
      context.go('/login');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-attempt navigation whenever auth state changes while still on splash.
    ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
      if (!_navigated && next.value != null) {
        _handleNavigation();
      }
    });

    final tokens = ThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _OrchestraLogotype(tokens: tokens),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Logotype ──────────────────────────────────────────────────────────────────

/// Renders the Orchestra logotype using theme tokens.
///
/// Intentionally a high-quality placeholder: swap [_LogoMark] for an
/// `SvgPicture` when the real asset is available.
class _OrchestraLogotype extends StatelessWidget {
  const _OrchestraLogotype({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LogoMark(tokens: tokens),
        const SizedBox(height: 20),
        _WordMark(tokens: tokens),
      ],
    );
  }
}

/// Orchestra logo mark from the app icon asset.
class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).orchestraLogoSemantics,
      child: Image.asset(
        'assets/images/logo.png',
        width: 88,
        height: 88,
      ),
    );
  }
}

/// "Orchestra" wordmark beneath the icon.
class _WordMark extends StatelessWidget {
  const _WordMark({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Orchestra',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 22,
        fontWeight: FontWeight.w300,
        color: tokens.fgMuted,
        letterSpacing: 3.0,
      ),
    );
  }
}
