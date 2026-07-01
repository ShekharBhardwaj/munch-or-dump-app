import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/core/widgets/forms.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';

/// Two steps in one screen: request a reset code, then set a new password with
/// it. On success we pop back to the sign-in screen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).forgotPassword(email);
      if (mounted) setState(() => _codeSent = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    final code = _code.text.trim();
    if (code.length < 6 || _password.text.length < 6) {
      setState(
        () =>
            _error = 'Enter the 6-digit code and a password of 6+ characters.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .resetPassword(email, code, _password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated — sign in.')),
      );
      context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      eyebrow: 'Reset password',
      titleDark: _codeSent ? 'Enter your' : 'Forgot your',
      titleMuted: _codeSent ? 'code.' : 'password?',
      subtitle: _codeSent
          ? 'If that email exists, a 6-digit reset code is on its way.'
          : 'Enter your email and we’ll send a reset code.',
      children: <Widget>[
        LabeledField(
          label: 'Email',
          child: TextField(
            controller: _email,
            enabled: !_busy && !_codeSent,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(hintText: 'you@example.com'),
          ),
        ),
        if (_codeSent) ...<Widget>[
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
              decoration: const InputDecoration(
                hintText: '123456',
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'New password',
            child: TextField(
              controller: _password,
              enabled: !_busy,
              obscureText: true,
              decoration: const InputDecoration(hintText: '••••••••'),
            ),
          ),
        ],
        if (_error != null) FormMessage(_error!),
        const SizedBox(height: 20),
        BlackCtaButton(
          label: _codeSent ? 'Update password' : 'Send reset code',
          expand: true,
          busy: _busy,
          trailingIcon: null,
          onTap: _codeSent ? _resetPassword : _requestCode,
        ),
      ],
    );
  }
}
