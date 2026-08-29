import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/onboarding_model.dart';
import '../../../widgets/onboarding_components.dart';

/// Who you are — the first thing asked, before any question about work.
///
/// Shantosh: *"when they type phone, bring them directly into it like how in
/// creating an account we get names first time, same like that, and then job
/// category — that will fix this too."*
///
/// The "this" it fixes is a bug that kept coming back. The app never asked for
/// a name anywhere, so the profile-completion nudge said "Add your name" on
/// every launch and there was nowhere to type one. Asking here, once, at the
/// point where every other app asks, removes the nag at its source.
///
/// The phone number is already known — it was typed on the sign-in screen and
/// verified — so it is shown rather than asked for again. Re-asking is how a
/// form tells somebody their last answer was not received.
class AccountStep extends StatefulWidget {
  final OnboardingData data;
  final String phone;
  final VoidCallback onChanged;

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const AccountStep({
    super.key,
    required this.data,
    required this.phone,
    required this.onChanged,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
  });

  @override
  State<AccountStep> createState() => _AccountStepState();
}

class _AccountStepState extends State<AccountStep> {
  // Anchors so finishing one answer carries you to the next, the same as the
  // trade and field-details steps. This step had none, which is why the
  // reveal animation felt inconsistent between tabs.
  final GlobalKey _emailKey = GlobalKey();
  final GlobalKey _passwordKey = GlobalKey();

  OnboardingData get data => widget.data;
  String get phone => widget.phone;
  void onChanged() => widget.onChanged();
  TextEditingController get nameController => widget.nameController;
  TextEditingController get emailController => widget.emailController;
  TextEditingController get passwordController => widget.passwordController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Create your account',
            style: AppTheme.serifTitle(
                fontSize: 26, color: AppTheme.inkOf(context))),
        const SizedBox(height: 6),
        Text(
          'Just your name to start. Everything else can wait.',
          style: AppTheme.sansRegular(
              fontSize: 14, color: AppTheme.inkMutedOf(context)),
        ),
        const SizedBox(height: 22),

        // Shown, not asked. It was verified a moment ago.
        if (phone.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppTheme.signalPositiveWash,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 17, color: AppTheme.signalPositive),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Number verified',
                          style: AppTheme.sansBold(
                              fontSize: 12,
                              color: AppTheme.signalPositive)),
                      Text(phone,
                          style: AppTheme.sansSemiBold(
                              fontSize: 14,
                              color: AppTheme.inkOf(context))),
                    ],
                  ),
                ),
              ],
            ),
          ),

        RevealedField(
          label: 'Your name *',
          child: _field(
            context,
            controller: nameController,
            hint: 'As employers should see it',
            next: _emailKey,
            onChanged: (v) {
              data.name = v;
              onChanged();
            },
          ),
        ),

        RevealedField(
          key: _emailKey,
          label: 'Email',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                context,
                controller: emailController,
                hint: 'you@example.com',
                keyboard: TextInputType.emailAddress,
                capitalise: false,
                next: _passwordKey,
                onChanged: (v) {
                  data.email = v;
                  onChanged();
                },
              ),
              const SizedBox(height: 6),
              Text(
                'Optional. Employers reach most candidates by phone, so leave '
                'this blank if you would rather.',
                style: AppTheme.sansRegular(
                    fontSize: 12, color: AppTheme.inkFaintOf(context)),
              ),
            ],
          ),
        ),

        RevealedField(
          key: _passwordKey,
          label: 'Password',
          visible: emailController.text.trim().isNotEmpty,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                context,
                controller: passwordController,
                hint: 'At least 8 characters',
                obscure: true,
                capitalise: false,
                onChanged: (v) {
                  data.password = v;
                  onChanged();
                },
              ),
              const SizedBox(height: 6),
              // Only appears once there is an email, because that is the only
              // thing it signs you in with. A password field above a blank
              // email is a question with no purpose.
              Text(
                'Lets you sign in on another phone with your email.',
                style: AppTheme.sansRegular(
                    fontSize: 12, color: AppTheme.inkFaintOf(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    TextInputType? keyboard,
    bool capitalise = true,
    bool obscure = false,

    /// Where the next question is. Submitting scrolls to it.
    GlobalKey? next,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        textInputAction:
            next == null ? TextInputAction.done : TextInputAction.next,
        onSubmitted: (_) {
          if (next == null) {
            FocusScope.of(context).unfocus();
          } else {
            revealNextQuestion(next);
          }
        },
        textCapitalization:
            capitalise ? TextCapitalization.words : TextCapitalization.none,
        onChanged: onChanged,
        style: AppTheme.sansMedium(fontSize: 15, color: AppTheme.inkOf(context)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.sansRegular(
              fontSize: 14, color: AppTheme.inkFaintOf(context)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
