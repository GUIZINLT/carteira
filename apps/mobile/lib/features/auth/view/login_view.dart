import 'package:carteira_core/carteira_core.dart';
import 'package:carteira_design_system/carteira_design_system.dart';
import 'package:flutter/material.dart';

import '../../../l10n/strings.dart';

/// Login screen. Authentication and session persistence belong to the Core.
class LoginView extends StatefulWidget {
  const LoginView({required this.auth, required this.onLogin, super.key});

  final AuthRepository auth;
  final VoidCallback onLogin;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = Strings.loginRequiredFields);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await widget.auth.login(email: email, password: password);
    if (!mounted) return;
    result.when(
      ok: (_) => widget.onLogin(),
      failure: (error) => setState(() => _errorMessage = error.message),
    );
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.xxxl,
              ),
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  Strings.appName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  Strings.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.semanticColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: Strings.email,
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  onChanged: (_) => _clearError(),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _password,
                  decoration: const InputDecoration(
                    labelText: Strings.password,
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _isLoading ? null : _signIn(),
                  onChanged: (_) => _clearError(),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(Strings.signIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }
}
