import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/core/widgets/forms.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';
import 'package:munch_or_dump/features/auth/auth_navigation.dart';

/// Enter the 6-digit code emailed by `/auth/register`. On success the account is
/// verified and a session is minted.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  late final TextEditingController _email = TextEditingController(
    text: widget.email,
  );
  final _code = TextEditingController();

  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final email = _email.text.trim();
    final code = _code.text.trim();
    if (email.isEmpty || code.length < 6) {
      setState(() => _error = 'Enter your email and the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final user = await ref
          .read(authControllerProvider.notifier)
          .completeVerification(email, code);
      if (!mounted) return;
      goAfterAuth(context, user);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).resendVerification(email);
      if (mounted) setState(() => _notice = 'A new code is on its way.');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      eyebrow: 'Verify email',
      titleDark: 'Check your',
      titleMuted: 'inbox.',
      subtitle: 'We sent a 6-digit code to verify your account.',
      children: <Widget>[
        LabeledField(
          label: 'Email',
          child: TextField(
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(hintText: 'you@example.com'),
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: '6-digit code',
          child: TextField(
            controller: _code,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            onSubmitted: (_) => _verify(),
            decoration: const InputDecoration(
              hintText: '123456',
              counterText: '',
            ),
          ),
        ),
        if (_error != null) FormMessage(_error!),
        if (_notice != null) FormMessage(_notice!, error: false),
        const SizedBox(height: 20),
        BlackCtaButton(
          label: 'Verify',
          expand: true,
          busy: _busy,
          trailingIcon: null,
          onTap: _verify,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _busy ? null : _resend,
            child: const Text('Resend code'),
          ),
        ),
      ],
    );
  }
}
