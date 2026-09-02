import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/job_seeker_provider.dart';
import '../../services/auth_service.dart';
import '../main_navigation_screen.dart';
import '../onboarding/profile_wizard_screen.dart';
import 'register_screen.dart';

/// Email + password sign-in.
///
/// Split onto its own screen so the entry point can lead with the phone number
/// alone. Stacking both methods on one screen forced a toggle above the fold
/// and made the primary action compete with the secondary one for attention.
class EmailSignInScreen extends StatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  State<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends State<EmailSignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!email.contains('@')) {
      setState(() => _error = 'Enter the email address on your account.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Enter your password.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await AuthService.login(email: email, password: password);
    if (!mounted) return;
    setState(() => _busy = false);

    if (!result.success) {
      // "No such account" is not an error to sit and stare at — it is the
      // commonest thing that happens to a first-time user, and the only useful
      // response is to offer to create one.
      if (AuthService.isUnknownAccount(result.message)) {
        _offerToCreateAccount(email);
        return;
      }
      setState(() => _error = result.message);
      return;
    }

    final session = result.session!;
    final provider = context.read<JobSeekerProvider>();
    provider.setAuthenticated(true, phone: session.phone);
    provider.updateProfileBasicInfo(name: session.name, email: session.email);

    // Pull the profile back down before deciding anything. signOut() wiped
    // the local copy, and the server is the only place it still exists.
    await provider.hydrateAfterSignIn();
    final profileComplete = provider.isProfileComplete;
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => profileComplete
            ? const MainNavigationScreen()
            : const ProfileWizardScreen(),
      ),
      (route) => false,
    );
  }

  /// Offers to register when the email is not on this device.
  Future<void> _offerToCreateAccount(String email) async {
    final create = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('No account found',
            style: AppTheme.sansBold(
                fontSize: 17, color: AppTheme.inkOf(context))),
        content: Text(
          'We could not find an account for $email. Would you like to create '
          'one? It takes about a minute.',
          style: AppTheme.sansRegular(
              fontSize: 14, color: AppTheme.inkMutedOf(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Try again',
                style: AppTheme.sansMedium(
                    fontSize: 14, color: AppTheme.inkMutedOf(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Create account',
                style: AppTheme.sansBold(
                    fontSize: 14, color: AppTheme.signalSource)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (create != true) {
      setState(() => _error = 'No account with that email yet.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.inkOf(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Continue with email',
                  style: AppTheme.serifTitle(fontSize: 28, color: AppTheme.inkOf(context))),
              const SizedBox(height: 6),
              Text(
                'Use the email and password on your Luckyboss account.',
                style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.inkMutedOf(context)),
              ),
              const SizedBox(height: 30),

              _label('Email address'),
              _field(
                controller: _emailController,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username, AutofillHints.email],
              ),
              const SizedBox(height: 18),

              _label('Password'),
              _field(
                controller: _passwordController,
                hint: 'Your password',
                obscure: _obscure,
                autofillHints: const [AutofillHints.password],
                onSubmitted: _submit,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 19,
                    color: AppTheme.inkMutedOf(context),
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppTheme.signalClosedWash,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, size: 17, color: AppTheme.signalClosed),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: AppTheme.sansMedium(
                                fontSize: 13, color: AppTheme.signalClosed)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 26),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryFillOf(context),
                    foregroundColor: AppTheme.onPrimaryFillOf(context),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _busy
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppTheme.onInkOf(context)),
                          ),
                        )
                      : Text('Sign in',
                          style: AppTheme.sansBold(fontSize: 15.5, color: AppTheme.onInkOf(context))),
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: GestureDetector(
                  onTap: _busy
                      ? null
                      : () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                  child: RichText(
                    text: TextSpan(
                      text: 'No account yet? ',
                      style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.inkMutedOf(context)),
                      children: [
                        TextSpan(
                          text: 'Create one',
                          style: AppTheme.sansBold(fontSize: 14, color: AppTheme.signalSource),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: AppTheme.sansMedium(fontSize: 13, color: AppTheme.inkMutedOf(context))),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    Iterable<String>? autofillHints,
    VoidCallback? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      enabled: !_busy,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted(),
      style: AppTheme.sansMedium(fontSize: 15, color: AppTheme.inkOf(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.sansRegular(fontSize: 15, color: AppTheme.inkFaintOf(context)),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.inkOf(context), width: 1.6),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
