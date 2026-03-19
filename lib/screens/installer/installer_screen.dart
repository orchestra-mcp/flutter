import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/startup/startup_gate_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

/// Install step descriptor.
enum _InstallStep { download, extract, setup }

String _stepLabel(_InstallStep step, AppLocalizations l10n) {
  switch (step) {
    case _InstallStep.download:
      return l10n.downloadOrchestra;
    case _InstallStep.extract:
      return l10n.extractFiles;
    case _InstallStep.setup:
      return l10n.setupComplete;
  }
}

extension on _InstallStep {
  IconData get icon {
    switch (this) {
      case _InstallStep.download:
        return Icons.download_rounded;
      case _InstallStep.extract:
        return Icons.folder_zip_rounded;
      case _InstallStep.setup:
        return Icons.check_circle_outline_rounded;
    }
  }
}

/// Shown when the Orchestra binary is not found on the host machine.
///
/// Guides the user through three steps: Download, Extract, Setup.
class InstallerScreen extends ConsumerStatefulWidget {
  const InstallerScreen({super.key});

  @override
  ConsumerState<InstallerScreen> createState() => _InstallerScreenState();
}

class _InstallerScreenState extends ConsumerState<InstallerScreen> {
  _InstallStep _currentStep = _InstallStep.download;
  bool _isDownloading = false;
  double _progress = 0.0;

  void _onDownload() {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });
    // Placeholder: simulate progress and advance steps.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _progress = 0.5;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _progress = 1.0;
          _isDownloading = false;
          _currentStep = _InstallStep.extract;
        });
      });
    });
  }

  void _onExtract() {
    setState(() => _currentStep = _InstallStep.setup);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Icon(
                  Icons.terminal_rounded,
                  size: 56,
                  color: tokens.accent,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.installOrchestra,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: tokens.fgBright,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.orchestraBinaryNotFound,
                  style: TextStyle(
                    fontSize: 14,
                    color: tokens.fgMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Step indicators
                _StepIndicatorRow(currentStep: _currentStep),
                const SizedBox(height: 32),
                // Step content card
                GlassCard(
                  child: _buildStepContent(tokens),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(OrchestraColorTokens tokens) {
    final l10n = AppLocalizations.of(context);
    switch (_currentStep) {
      case _InstallStep.download:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.downloadOrchestra,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: tokens.fgBright,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.downloadLatestBinary,
              style: TextStyle(fontSize: 13, color: tokens.fgMuted),
            ),
            const SizedBox(height: 16),
            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: tokens.border.withValues(alpha: 0.3),
                color: tokens.accent,
              ),
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).toInt()}%',
                style: TextStyle(fontSize: 12, color: tokens.fgDim),
                textAlign: TextAlign.center,
              ),
            ] else
              ElevatedButton.icon(
                onPressed: _onDownload,
                icon: const Icon(Icons.download_rounded),
                label: Text(l10n.downloadOrchestra),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        );

      case _InstallStep.extract:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.extractFiles,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: tokens.fgBright,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.extractInstallBinary,
              style: TextStyle(fontSize: 13, color: tokens.fgMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _onExtract,
              icon: const Icon(Icons.folder_zip_rounded),
              label: Text(l10n.extractAndInstall),
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );

      case _InstallStep.setup:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.green.shade400, size: 28),
                const SizedBox(width: 10),
                Text(
                  l10n.setupComplete,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: tokens.fgBright,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.orchestraInstalledSuccessfully,
              style: TextStyle(fontSize: 13, color: tokens.fgMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(startupGateProvider.notifier).recheck(),
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(l10n.getStarted),
            ),
          ],
        );
    }
  }
}

class _StepIndicatorRow extends StatelessWidget {
  const _StepIndicatorRow({required this.currentStep});

  final _InstallStep currentStep;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    const steps = _InstallStep.values;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Container(
              width: 40,
              height: 1,
              color: steps[i].index <= currentStep.index
                  ? tokens.accent
                  : tokens.border.withValues(alpha: 0.4),
            ),
          _StepDot(
            step: steps[i],
            isActive: steps[i] == currentStep,
            isDone: steps[i].index < currentStep.index,
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.step,
    required this.isActive,
    required this.isDone,
  });

  final _InstallStep step;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final color = isDone || isActive ? tokens.accent : tokens.border;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? tokens.accent
                : isDone
                    ? tokens.accent.withValues(alpha: 0.3)
                    : tokens.border.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: Icon(
              isDone ? Icons.check : step.icon,
              size: 14,
              color: isActive ? Colors.white : color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _stepLabel(step, AppLocalizations.of(context)),
          style: TextStyle(
            fontSize: 10,
            color: isActive ? tokens.fgBright : tokens.fgDim,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
