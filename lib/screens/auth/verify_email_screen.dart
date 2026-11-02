import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/primary_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _cooldownSeconds = 60;

  Timer? _timer;
  int _cooldown = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldown = 0);
      } else if (mounted) {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _checkVerified() async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final verified = await auth.checkVerified();
    if (!mounted) return; // verified: the gate already moved on

    if (!verified && auth.errorMessage == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Not verified yet. Open the link in your email, then try again.',
          ),
        ),
      );
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final sent = await auth.resendVerification();
    if (!mounted || !sent) return;

    _startCooldown();
    messenger.showSnackBar(
      const SnackBar(content: Text('Verification email sent.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    child: Container(
                      height: 72,
                      width: 72,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_unread_outlined,
                        size: 36,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Verify your email',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'We sent a verification link to',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    auth.email ?? '',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Open the link, then come back and tap the button below. '
                    'Check your spam folder if you do not see it.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    ErrorBanner(message: auth.errorMessage!),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: "I've verified my email",
                    isLoading: auth.isBusy,
                    onPressed: _checkVerified,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed:
                        (auth.isBusy || _cooldown > 0) ? null : _resend,
                    child: Text(
                      _cooldown > 0
                          ? 'Resend email (${_cooldown}s)'
                          : 'Resend email',
                    ),
                  ),
                  TextButton(
                    onPressed: auth.isBusy ? null : auth.logout,
                    child: const Text('Use a different account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}