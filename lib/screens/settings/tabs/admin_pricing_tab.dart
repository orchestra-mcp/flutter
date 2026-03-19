import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/admin_settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Admin pricing tab — manage pricing plan names, prices, and billing URL.
class AdminPricingTab extends ConsumerStatefulWidget {
  const AdminPricingTab({super.key});

  @override
  ConsumerState<AdminPricingTab> createState() => _AdminPricingTabState();
}

class _AdminPricingTabState extends ConsumerState<AdminPricingTab> {
  final _freePlanNameCtrl = TextEditingController();
  final _proPlanNameCtrl = TextEditingController();
  final _proPriceCtrl = TextEditingController();
  final _enterprisePriceCtrl = TextEditingController();
  final _billingUrlCtrl = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  void _populateFields(Map<String, dynamic> data) {
    if (_initialized) return;
    _initialized = true;
    _freePlanNameCtrl.text = data['free_plan_name'] as String? ?? 'Free';
    _proPlanNameCtrl.text = data['pro_plan_name'] as String? ?? 'Pro';
    _proPriceCtrl.text = data['pro_price'] as String? ?? '';
    _enterprisePriceCtrl.text = data['enterprise_price'] as String? ?? '';
    _billingUrlCtrl.text = data['billing_url'] as String? ?? '';
  }

  @override
  void dispose() {
    _freePlanNameCtrl.dispose();
    _proPlanNameCtrl.dispose();
    _proPriceCtrl.dispose();
    _enterprisePriceCtrl.dispose();
    _billingUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).updateAdminSetting('pricing', {
        'free_plan_name': _freePlanNameCtrl.text,
        'pro_plan_name': _proPlanNameCtrl.text,
        'pro_price': _proPriceCtrl.text,
        'enterprise_price': _enterprisePriceCtrl.text,
        'billing_url': _billingUrlCtrl.text,
      });
      ref.invalidate(adminSettingProvider('pricing'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).settingsSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToSave}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final settingAsync = ref.watch(adminSettingProvider('pricing'));

    return settingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${AppLocalizations.of(context).failedToLoad}: $e')),
      data: (data) {
        final l10n = AppLocalizations.of(context);
        _populateFields(data);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader(tokens, l10n.adminPricingPlans),
            const SizedBox(height: 4),
            Text(
              l10n.adminPricingPlansDesc,
              style: TextStyle(fontSize: 13, color: tokens.fgDim),
            ),
            const SizedBox(height: 16),

            // Free Plan
            _fieldLabel(tokens, l10n.adminFreePlanName),
            const SizedBox(height: 6),
            _field(tokens, _freePlanNameCtrl, hint: 'Free'),
            const SizedBox(height: 16),

            // Pro Plan
            _fieldLabel(tokens, l10n.adminProPlanName),
            const SizedBox(height: 6),
            _field(tokens, _proPlanNameCtrl, hint: 'Pro'),
            const SizedBox(height: 16),

            // Pro Price
            _fieldLabel(tokens, l10n.adminProPrice),
            const SizedBox(height: 6),
            _field(tokens, _proPriceCtrl, hint: '\$19/mo'),
            const SizedBox(height: 16),

            // Enterprise Price
            _fieldLabel(tokens, l10n.adminEnterprisePriceLabel),
            const SizedBox(height: 6),
            _field(tokens, _enterprisePriceCtrl, hint: 'Custom'),

            const SizedBox(height: 24),
            Divider(color: tokens.border.withValues(alpha: 0.4)),
            const SizedBox(height: 20),

            // Billing URL
            _sectionHeader(tokens, l10n.adminBilling),
            const SizedBox(height: 12),
            _fieldLabel(tokens, l10n.adminBillingUrl),
            const SizedBox(height: 6),
            _field(tokens, _billingUrlCtrl, hint: l10n.adminBillingUrlHint),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(AppLocalizations.of(context).save),
              ),
            ),
          ],
        );
      },
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

  Widget _fieldLabel(OrchestraColorTokens tokens, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tokens.fgDim,
          letterSpacing: 0.4,
        ),
      );

  Widget _field(
    OrchestraColorTokens tokens,
    TextEditingController ctrl, {
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: tokens.fgBright, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: tokens.fgDim),
        filled: true,
        fillColor: tokens.bgAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      ),
    );
  }
}
