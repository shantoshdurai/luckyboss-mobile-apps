import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/employer_provider.dart';
import '../../widgets/ledger_components.dart';
import '../../widgets/lucky_boss_brand_logo.dart';
import '../employer_main_navigation_screen.dart';
import 'company_registration_screen.dart';

/// The login screen is where the logo has to do all the work.
///
/// In the Ledger system every hue on screen carries data meaning, so this screen
/// is deliberately colourless apart from the wordmark and the 2px rule beneath
/// it. Nothing competes with the mark. The paper ground and the hairline rules
/// do the rest — the screen reads as a document, not a landing page.
class EmployerLoginScreen extends StatefulWidget {
  const EmployerLoginScreen({super.key});

  @override
  State<EmployerLoginScreen> createState() => _EmployerLoginScreenState();
}

class _EmployerLoginScreenState extends State<EmployerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Offers registration when the email is not one we know.
  Future<void> _offerToRegister(String email) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('No account for that email',
            style: AppTheme.sansBold(fontSize: 16, color: AppTheme.ink)),
        content: Text(
          'We could not find a company registered to $email on this device. '
          'Register your company and Lucky Boss will verify it before your '
          'jobs go live.',
          style: AppTheme.body(color: AppTheme.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Try again',
                style: AppTheme.body(color: AppTheme.inkMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Register company',
                style: AppTheme.sansBold(
                    fontSize: 14, color: AppTheme.signalSource)),
          ),
        ],
      ),
    );

    if (go != true || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CompanyRegistrationScreen()),
    );
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final provider = context.read<EmployerProvider>();
    await provider.hydrate();
    if (!mounted) return;

    final email = _emailController.text.trim().toLowerCase();
    final registered = provider.company.email.trim().toLowerCase();

    // No account, or a different one — refuse and point at registration.
    //
    // This used to accept any address and silently invent a company from the
    // email domain, so signing in as anything at all produced a working
    // employer account. Shantosh wants sir to see the real shape of the
    // product: you register a company, it gets checked, then you sign in. An
    // app that lets a stranger straight in is not that product, and demoing it
    // teaches the wrong thing about how the platform works.
    if (registered.isEmpty || registered != email) {
      setState(() => _submitting = false);
      // Not an error to sit and stare at. This is the commonest thing that
      // happens to a first-time employer, and the only useful response is to
      // offer the thing they actually need.
      await _offerToRegister(email);
      return;
    }

    // TODO: try POST /api/v1/auth/login first once an employer login route
    // exists, and fall back to this device check only when nothing answers.
    provider.setAuthenticated(true);
    await provider.flush();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const EmployerMainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---- The mark, at full strength, with nothing beside it ----
                    const SizedBox(height: 8),
                    const Center(child: LuckyBossBrandLogo(height: 44)),
                    const SizedBox(height: 14),
                    Center(
                      child: SizedBox(width: 132, child: const BrandRule()),
                    ),
                    const SizedBox(height: 40),

                    const MetaText('Recruiter workspace'),
                    const SizedBox(height: 8),
                    Text('Sign in', style: AppTheme.screenTitle()),
                    const SizedBox(height: 6),
                    Text(
                      'Manage vacancies, candidate pipelines and hiring across your company.',
                      style: AppTheme.body(),
                    ),
                    const SizedBox(height: 28),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.signalClosedWash,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusRow,
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: AppTheme.body(color: AppTheme.signalClosed),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const MetaText('Work email'),
                    const SizedBox(height: 7),
                    TextFormField(
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      style: AppTheme.body(color: AppTheme.ink),
                      decoration: const InputDecoration(
                        hintText: 'you@company.com',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter your work email';
                        }
                        if (!v.contains('@')) {
                          return 'That does not look like an email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    const MetaText('Password'),
                    const SizedBox(height: 7),
                    TextFormField(
                      // Enter submits the form. Left as it was — this field
                      // already said what Enter does, so it never reached the
                      // traversal fallback the other fields were falling into.
                      textInputAction: TextInputAction.done,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      style: AppTheme.body(color: AppTheme.ink),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                            color: AppTheme.inkFaint,
                          ),
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                        ),
                      ),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Enter your password'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) =>
                                      setState(() => _rememberMe = v ?? false),
                                  side: const BorderSide(
                                    color: AppTheme.inkFaint,
                                    width: 1.2,
                                  ),
                                  activeColor: AppTheme.ink,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Remember me',
                                  style: AppTheme.small(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: const Size(0, 36),
                          ),
                          child: Text(
                            'Forgot password',
                            style: AppTheme.small(color: AppTheme.inkMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppTheme.surface,
                                ),
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: 28),

                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: const MetaText('New company'),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    OutlinedButton(
                      // Was `onPressed: () {}` — a button that rendered,
                      // invited a tap and did nothing at all.
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CompanyRegistrationScreen(),
                        ),
                      ),
                      child: const Text('Register your company'),
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: MetaText(
                        'Growth partner in your hiring journey',
                        size: 9,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
