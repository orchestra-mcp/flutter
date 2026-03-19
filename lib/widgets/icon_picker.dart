import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Curated set of Material icons suitable for entity customisation.
const List<IconData> kPickerIcons = [
  // Notes & docs
  Icons.sticky_note_2_rounded,
  Icons.description_rounded,
  Icons.article_rounded,
  Icons.note_alt_rounded,
  Icons.edit_note_rounded,
  Icons.auto_stories_rounded,

  // Folders & projects
  Icons.folder_rounded,
  Icons.folder_special_rounded,
  Icons.source_rounded,
  Icons.inventory_2_rounded,
  Icons.work_rounded,
  Icons.business_center_rounded,

  // Code & dev
  Icons.code_rounded,
  Icons.terminal_rounded,
  Icons.data_object_rounded,
  Icons.bug_report_rounded,
  Icons.build_rounded,
  Icons.settings_rounded,

  // People & agents
  Icons.smart_toy_rounded,
  Icons.person_rounded,
  Icons.group_rounded,
  Icons.support_agent_rounded,
  Icons.psychology_rounded,
  Icons.emoji_objects_rounded,

  // Misc
  Icons.bolt_rounded,
  Icons.star_rounded,
  Icons.favorite_rounded,
  Icons.bookmark_rounded,
  Icons.flag_rounded,
  Icons.rocket_launch_rounded,

  // Media & creative
  Icons.palette_rounded,
  Icons.brush_rounded,
  Icons.camera_alt_rounded,
  Icons.music_note_rounded,
  Icons.movie_rounded,
  Icons.image_rounded,

  // Communication
  Icons.chat_rounded,
  Icons.forum_rounded,
  Icons.mail_rounded,
  Icons.notifications_rounded,
  Icons.campaign_rounded,
  Icons.send_rounded,

  // Navigation & status
  Icons.explore_rounded,
  Icons.public_rounded,
  Icons.cloud_rounded,
  Icons.shield_rounded,
  Icons.lock_rounded,
  Icons.key_rounded,

  // Data & analytics
  Icons.analytics_rounded,
  Icons.pie_chart_rounded,
  Icons.bar_chart_rounded,
  Icons.timeline_rounded,
  Icons.account_tree_rounded,
  Icons.hub_rounded,
];

/// A grid of Material icons for the user to pick from.
class IconPicker extends StatefulWidget {
  const IconPicker({
    super.key,
    this.selectedCodePoint,
    required this.onIconSelected,
  });

  final int? selectedCodePoint;
  final ValueChanged<int> onIconSelected;

  @override
  State<IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker> {
  late int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedCodePoint;
  }

  void _pick(IconData icon) {
    setState(() => _selected = icon.codePoint);
    widget.onIconSelected(icon.codePoint);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return Semantics(
      label: AppLocalizations.of(context).iconPickerSemantics,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: kPickerIcons.length,
        itemBuilder: (context, index) {
          final icon = kPickerIcons[index];
          final isActive = _selected == icon.codePoint;
          return Semantics(
            label: AppLocalizations.of(context).iconPickerOptionSemantics,
            selected: isActive,
            button: true,
            child: GestureDetector(
              onTap: () => _pick(icon),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isActive
                      ? tokens.accent.withValues(alpha: 0.18)
                      : tokens.bgAlt.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive ? tokens.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isActive ? tokens.accent : tokens.fgMuted,
                  size: 22,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shows [IconPicker] as a glass-styled bottom sheet.
///
/// Returns the selected icon's codePoint, or `null` if dismissed.
Future<int?> showIconPicker({
  required BuildContext context,
  int? initialCodePoint,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      final tokens = ThemeTokens.of(ctx);
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 420),
          decoration: BoxDecoration(
            color: tokens.bgAlt.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.borderFaint, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: tokens.fgDim.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                AppLocalizations.of(context).chooseIcon,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: IconPicker(
                    selectedCodePoint: initialCodePoint,
                    onIconSelected: (cp) => Navigator.of(ctx).pop(cp),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
