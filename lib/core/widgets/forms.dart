import 'package:flutter/material.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';

/// Shared editorial form chrome: a graph-paper page with a back button, an
/// eyebrow + two-tone headline, an optional subtitle, then the form body. Used
/// across the auth flow and onboarding so every form reads the same.
class FormScaffold extends StatelessWidget {
  const FormScaffold({
    required this.eyebrow,
    required this.titleDark,
    required this.titleMuted,
    required this.children,
    this.subtitle,
    super.key,
  });

  final String eyebrow;
  final String titleDark;
  final String titleMuted;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: GridBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
            children: <Widget>[
              Eyebrow(eyebrow, spacing: 3.6),
              const SizedBox(height: 12),
              TwoToneHeadline(
                dark: titleDark,
                muted: titleMuted,
                size: 30,
                align: TextAlign.left,
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// A small field label above a form control.
class LabeledField extends StatelessWidget {
  const LabeledField({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// A red error line / an emerald notice line for form feedback.
class FormMessage extends StatelessWidget {
  const FormMessage(this.message, {this.error = true, super.key});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: error ? AppColors.concernHigh : AppColors.brandDeep,
        ),
      ),
    );
  }
}

/// A selectable editorial pill for single/multi-choice groups. Emerald-tinted
/// when [selected], neutral otherwise.
class SelectChip extends StatelessWidget {
  const SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Selection is conveyed by fill/border/text color; expose it non-visually
    // too so screen readers announce "selected" (and color-blind users aren't
    // left guessing) — matching the ChoiceChip/FilterChip this replaces.
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFECFDF5)
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? AppColors.brand : AppColors.hairline,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.brandDeep
                      : AppColors.inkSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tappable settings/nav row: leading icon, label, trailing chevron. Grouped
/// with hairline dividers on the account and profile surfaces.
class NavRow extends StatelessWidget {
  const NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: AppColors.inkSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.inkPrimary,
                ),
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.inkGhost,
                ),
          ],
        ),
      ),
    );
  }
}
