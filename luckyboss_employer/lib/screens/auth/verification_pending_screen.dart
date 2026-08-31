import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/employer_job.dart';
import '../../providers/employer_provider.dart';
import '../../widgets/lucky_boss_brand_logo.dart';
import '../../widgets/reviewer_tools.dart';
import '../employer_main_navigation_screen.dart';

/// Where a company waits after registering.
///
/// Deliberately not a spinner and not a fake progress bar. Shantosh asked for
/// *"letting them know we contact them after verification"*, and the honest
/// version of that is a screen that says what happens next, who will call, and
/// what they can do meanwhile — then stops. A pretend progress bar for a step
/// that depends on a human reading a certificate is a lie with a countdown on
/// it.
///
/// They are let into the app, because browsing candidates before posting is
/// exactly how an employer decides Lucky Boss is worth paying for. What they
/// cannot do is publish, and [EmployerProvider.canPost] gates that.
class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final company = context.watch<EmployerProvider>().company;
    final rejected = company.status == CompanyStatus.rejected;

    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pushed from three places and had no way back from any of them.
              // Shown only when there is something to pop — after registering,
              // this screen *is* the stack, and a back arrow to nowhere is
              // worse than none.
              Row(
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40),
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back,
                          color: AppTheme.inkOf(context)),
                    ),
                  const LuckyBossBrandLogo(height: 30),
                ],
              ),
              const Spacer(),

              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rejected
                      ? AppTheme.signalClosedWash
                      : AppTheme.signalAttentionWash,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  rejected ? Icons.error_outline : Icons.hourglass_top_rounded,
                  size: 26,
                  color: rejected
                      ? AppTheme.signalClosed
                      : AppTheme.signalAttention,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                rejected
                    ? 'We could not verify your company'
                    : 'We have your documents',
                style: AppTheme.serifTitle(
                    fontSize: 27, color: AppTheme.inkOf(context)),
              ),
              const SizedBox(height: 10),
              Text(
                rejected
                    ? (company.reviewNote ??
                        'Something did not match. Our team will call you to '
                            'sort it out.')
                    : 'Luckyboss checks every employer before candidates see '
                        'their jobs. We will call ${company.phone.isEmpty ? 'you' : company.phone} '
                        'to finish — usually within one working day.',
                style: AppTheme.sansRegular(
                    fontSize: 15, color: AppTheme.inkMutedOf(context)),
              ),

              const SizedBox(height: 24),
              _StatusRow(company: company),
              const SizedBox(height: 20),
              const ReviewerTools(),

              const Spacer(),

              // Not a dead-end. Browsing the database before posting is how an
              // employer decides we are worth paying for.
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.groups_outlined,
                        size: 18, color: AppTheme.inkMutedOf(context)),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'You can look through candidates and draft a vacancy '
                        'now. Publishing unlocks once you are verified.',
                        style: AppTheme.sansMedium(
                            fontSize: 13, color: AppTheme.inkOf(context)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EmployerMainNavigationScreen()),
                    (route) => false,
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Look around',
                      style: AppTheme.sansBold(
                          fontSize: 15,
                          color: AppTheme.onPrimaryFillOf(context))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The three steps of verification, and which one we are on.
///
/// Shown because "awaiting verification" on its own tells a company nothing
/// about whether anything is happening. Naming the steps makes the wait
/// legible even though none of them can be hurried.
class _StatusRow extends StatelessWidget {
  final CompanyProfile company;

  const _StatusRow({required this.company});

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Documents received', CompanyStatus.submitted),
      ('Checked by Luckyboss', CompanyStatus.underReview),
      ('Verified — you can post', CompanyStatus.verified),
    ];

    final reachedIndex = switch (company.status) {
      CompanyStatus.draft => -1,
      CompanyStatus.submitted => 0,
      CompanyStatus.underReview => 1,
      CompanyStatus.verified => 2,
      CompanyStatus.rejected => 0,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Row(
              children: [
                Icon(
                  i <= reachedIndex
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: i <= reachedIndex
                      ? AppTheme.signalPositive
                      : AppTheme.inkFaintOf(context),
                ),
                const SizedBox(width: 11),
                Text(
                  steps[i].$1,
                  style: i <= reachedIndex
                      ? AppTheme.sansSemiBold(
                          fontSize: 14, color: AppTheme.inkOf(context))
                      : AppTheme.sansRegular(
                          fontSize: 14, color: AppTheme.inkFaintOf(context)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
