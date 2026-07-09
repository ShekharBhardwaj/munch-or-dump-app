import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/models/profile_update.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/palette.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/core/widgets/forms.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';
import 'package:munch_or_dump/features/onboarding/personalization_options.dart';

/// Capture the personalization profile that powers "For You" notes. Pre-fills
/// from any existing profile so it doubles as the edit-profile screen.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String? _persona;
  final Set<String> _goals = <String>{};
  final Set<String> _dietary = <String>{};
  final Set<String> _conditions = <String>{};
  final _context = TextEditingController();

  bool _busy = false;
  String? _error;
  bool _seeded = false;

  @override
  void dispose() {
    _context.dispose();
    super.dispose();
  }

  void _seedFromProfile() {
    if (_seeded) return;
    _seeded = true;
    final profile = ref.read(authControllerProvider).valueOrNull?.profile;
    if (profile == null) return;
    _persona = profile.persona;
    _goals.addAll(profile.goalsList);
    _dietary.addAll(profile.dietaryList);
    _conditions.addAll(profile.conditionsList);
    _context.text = profile.context ?? '';
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            ProfileUpdate(
              persona: _persona,
              goals: _goals.toList(),
              dietary: _dietary.toList(),
              conditions: _conditions.toList(),
              context: _context.text.trim(),
            ),
          );
      if (!mounted) return;
      context.goNamed(Routes.home);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggle(Set<String> set, String value) => setState(() {
    if (!set.remove(value)) set.add(value);
  });

  @override
  Widget build(BuildContext context) {
    _seedFromProfile();
    return FormScaffold(
      eyebrow: 'Personalize',
      titleDark: 'Tell us',
      titleMuted: 'about you.',
      subtitle:
          'Used to tailor your verdicts and “For You” notes. You can change '
          'this anytime.',
      children: <Widget>[
        _ChoiceGroup(
          title: 'Who are you shopping for?',
          options: personaOptions,
          isSelected: (v) => _persona == v,
          onTap: _busy
              ? null
              : (v) => setState(() => _persona = _persona == v ? null : v),
        ),
        _ChoiceGroup(
          title: 'Goals',
          options: goalOptions,
          isSelected: _goals.contains,
          onTap: _busy ? null : (v) => _toggle(_goals, v),
        ),
        _ChoiceGroup(
          title: 'Dietary preferences',
          options: dietaryOptions,
          isSelected: _dietary.contains,
          onTap: _busy ? null : (v) => _toggle(_dietary, v),
        ),
        _ChoiceGroup(
          title: 'Health conditions',
          options: conditionOptions,
          isSelected: _conditions.contains,
          onTap: _busy ? null : (v) => _toggle(_conditions, v),
        ),
        LabeledField(
          label: 'Anything else? (optional)',
          child: TextField(
            controller: _context,
            enabled: !_busy,
            maxLength: maxContextChars,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g. avoiding seed oils, training for a marathon',
            ),
          ),
        ),
        if (_error != null) FormMessage(_error!),
        const SizedBox(height: 20),
        BlackCtaButton(
          label: 'Save',
          expand: true,
          busy: _busy,
          trailingIcon: null,
          onTap: _save,
        ),
      ],
    );
  }
}

/// A titled group of [SelectChip]s for a single- or multi-select field.
class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
    required this.title,
    required this.options,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final List<LabeledOption> options;
  final bool Function(String) isSelected;
  final void Function(String)? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: palette.inkPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final option in options)
                SelectChip(
                  label: option.label,
                  selected: isSelected(option.value),
                  onTap: onTap == null ? null : () => onTap!(option.value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
