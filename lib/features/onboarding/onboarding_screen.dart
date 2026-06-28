import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/models/profile_update.dart';
import 'package:munch_or_dump/core/router/routes.dart';
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

  @override
  Widget build(BuildContext context) {
    _seedFromProfile();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Personalize')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Text(
              'Tell us about you',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Used to tailor your verdicts and "For You" notes. You can change '
              'this anytime.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Who are you shopping for?',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final option in personaOptions)
                    ChoiceChip(
                      label: Text(option.label),
                      selected: _persona == option.value,
                      onSelected: _busy
                          ? null
                          : (selected) => setState(
                              () => _persona = selected ? option.value : null,
                            ),
                    ),
                ],
              ),
            ),
            _MultiSection(
              title: 'Goals',
              options: goalOptions,
              selected: _goals,
              busy: _busy,
              onChanged: () => setState(() {}),
            ),
            _MultiSection(
              title: 'Dietary preferences',
              options: dietaryOptions,
              selected: _dietary,
              busy: _busy,
              onChanged: () => setState(() {}),
            ),
            _MultiSection(
              title: 'Health conditions',
              options: conditionOptions,
              selected: _conditions,
              busy: _busy,
              onChanged: () => setState(() {}),
            ),
            _Section(
              title: 'Anything else? (optional)',
              child: TextField(
                controller: _context,
                enabled: !_busy,
                maxLength: maxContextChars,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. avoiding seed oils, training for a marathon',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            if (_error != null) ...<Widget>[
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 20),
      ],
    );
  }
}

class _MultiSection extends StatelessWidget {
  const _MultiSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.busy,
    required this.onChanged,
  });

  final String title;
  final List<LabeledOption> options;
  final Set<String> selected;
  final bool busy;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (final option in options)
            FilterChip(
              label: Text(option.label),
              selected: selected.contains(option.value),
              onSelected: busy
                  ? null
                  : (isSelected) {
                      if (isSelected) {
                        selected.add(option.value);
                      } else {
                        selected.remove(option.value);
                      }
                      onChanged();
                    },
            ),
        ],
      ),
    );
  }
}
