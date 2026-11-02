import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_spacing.dart';
import '../providers/auth_provider.dart';
import '../widgets/primary_button.dart';
import 'auth/login_screen.dart';
import 'auth/verify_email_screen.dart';
import 'home/home_screen.dart';

/// Chooses which screen to show based on the sign-in state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((a) => a.status);

    return switch (status) {
      AuthStatus.loading => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.unverified => const VerifyEmailScreen(),
      AuthStatus.authenticated => const HomeScreen(),
      AuthStatus.profileError => const _ProfileErrorView(),
    };
  }
}

class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined,
                    size: 56, color: theme.colorScheme.error),
                const SizedBox(height: AppSpacing.md),
                Text(
                  auth.errorMessage ?? 'Something went wrong.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Try again',
                  onPressed: auth.retryProfile,
                ),
                TextButton(
                  onPressed: auth.logout,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}