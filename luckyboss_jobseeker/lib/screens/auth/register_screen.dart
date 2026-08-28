import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/job_seeker_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/phone_number_field.dart';
import '../onboarding/profile_wizard_screen.dart';

/// Candidate registration — spec §29 "JOB SEEKER MINIMUM REGISTRATION":
/// Name, Phone, Email, Password, with country optional.
///
/// The spec calls this the *minimum* registration deliberately: it exists so a
/// candidate can be browsing jobs within a minute, with the full resume profile
/// (§31) filled in afterwards. So nothing optional is asked for here, and the
/// country comes from the phone field's own selector rather than a second
/// dropdown asking the same question twice.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneKey = GlobalKey<PhoneNumberFieldState>();

  String _e164 = '';
  PhoneFormat _format = PhoneFormat.all.first;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  /// Laravel enforces min:8 on registration. Checking here too means the user
  /// finds out while typing rather than after a round trip.
  static const int _minPassword = 8;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phoneField = _phoneKey.currentState;

    if (name.isEmpty) {
      setState(() => _error = 'Enter your full name.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (phoneField == null || !phoneField.isComplete) {
      setState(() => _error =
          'Enter your ${_format.digitCount}-digit ${_format.name} mobile number.');
      return;
    }
    if (password.length < _minPassword) {
      setState(() => _error = 'Use at least $_minPassword characters for your password.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await AuthService.register(
      name: name,
      email: email,
      phone: _e164,
      countryCode: _format.iso,
      password: password,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (!result.success) {
      setState(() => _error = result.message);
      return;
    }

    final provider = context.read<JobSeekerProvider>();
    provider.setAuthenticated(true, phone: _e164);
    provider.setDemoMode(false);
    provider.updateProfileBasicInfo(name: name, email: email);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ProfileWizardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final password = _passwordController.text;

    return Scaffold(
      appBar: AppBar(
        title: Text('Create account',
            style: AppTheme.sansBold(fontSize: 17, color: AppTheme.inkOf(context))),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Takes under a minute',
                style: AppTheme.serifTitle(fontSize: 26, color: AppTheme.inkOf(context)),
              ),
              const SizedBox(height: 6),
              Text(
                'Start searching and saving jobs straight away. Your full profile can wait.',
                style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.inkMutedOf(context)),
              ),
              const SizedBox(height: 26),

              _label('Full name'),
              _field(
                controller: _nameController,
                hint: 'As it appears on your identification',
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: 18),

              _label('Email address'),
              _field(
                controller: _emailController,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 18),

              _label('Mobile number'),
              PhoneNumberField(
                key: _phoneKey,
                enabled: !_busy,
                onChanged: (v) => _e164 = v,
                onCountryChanged: (f) => setState(() => _format = f),
              ),
              const SizedBox(height: 18),

              _label('Password'),
              _field(
                controller: _passwordController,
                hint: 'At least $_minPassword characters',
                obscure: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => setState(() {}),
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 19,
                    color: AppTheme.inkMutedOf(context),
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              if (password.isNotEmpty) ...[
                const SizedBox(height: 8),
                _passwordMeter(password),
              ],

              if (_error != null) ...[
                const SizedBox(height: 18),
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
                      : Text('Create account',
                          style: AppTheme.sansBold(fontSize: 15.5, color: AppTheme.onInkOf(context))),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'By continuing you agree to the Lucky Boss Terms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: AppTheme.sansRegular(fontSize: 12, color: AppTheme.inkFaintOf(context)),
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

  /// Length-based strength only, and labelled as such.
  ///
  /// A meter that promises more than it measures teaches users that "Strong"
  /// means safe, when all it checked was that they typed enough characters.
  Widget _passwordMeter(String password) {
    final length = password.length;
    final (label, color, fill) = switch (length) {
      < _minPassword => ('Too short', AppTheme.signalClosed, 0.25),
      < 12 => ('Acceptable', AppTheme.signalAttention, 0.6),
      _ => ('Good length', AppTheme.signalPositive, 1.0),
    };

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 4,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: AppTheme.sansMedium(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    Iterable<String>? autofillHints,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      enabled: !_busy,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: AppTheme.sansMedium(fontSize: 15, color: AppTheme.inkOf(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.sansRegular(fontSize: 14.5, color: AppTheme.inkFaintOf(context)),
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
