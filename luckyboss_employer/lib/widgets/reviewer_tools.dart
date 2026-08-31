import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/employer_provider.dart';

/// A switch that approves this company without a server.
///
/// Shantosh: *"employer app has only registering… have an option we can enable
/// to accept, to know how it works on posting the jobs too — we can't do that
/// right now."* He is right, and it was my doing: verification gates posting,
/// boosting and contact credits, and since only a server may grant it, every
/// build we handed over had its entire second half unreachable.
///
/// So this exists, and it is deliberately conspicuous rather than hidden. It is
/// in a red-bordered card, labelled as a testing tool, and it says plainly that
/// real verification is a person at Lucky Boss reading documents. A quiet
/// backdoor that looked like a normal setting would be far worse — somebody
/// would eventually ship it believing companies were being checked.
///
/// **Delete this widget when `POST /api/v1/employer/verify` exists.** It is one
/// file and one provider method, kept apart from everything else for exactly
/// that reason.
class ReviewerTools extends StatelessWidget {
  const ReviewerTools({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployerProvider>();
    final verified = provider.company.isVerified;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.signalClosedWash,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.signalClosed.withValues(alpha: 0.4),
          // Dashed would be better; a heavier border is the next best way to
          // say "this is not part of the product".
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined,
                  size: 17, color: AppTheme.signalClosed),
              const SizedBox(width: 8),
              Text('TESTING ONLY — NOT PART OF THE APP',
                  style: AppTheme.sansBold(
                          fontSize: 9.5, color: AppTheme.signalClosed)
                      .copyWith(letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            verified
                ? 'This company is approved, so posting, boosting and contact '
                    'credits are unlocked.'
                : 'Approve this company so you can try posting a job, boosting '
                    'it and revealing candidate contacts.',
            style: AppTheme.sansMedium(
                fontSize: 13, color: AppTheme.inkOf(context)),
          ),
          const SizedBox(height: 6),
          Text(
            'In the real product only Luckyboss can approve a company, after '
            'someone has read the documents. This switch exists because there '
            'is no server yet.',
            style: AppTheme.sansRegular(
                fontSize: 11.5, color: AppTheme.inkMutedOf(context)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: verified
                ? OutlinedButton.icon(
                    onPressed: provider.revokeApproval,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.undo,
                        size: 17, color: AppTheme.signalClosed),
                    label: Text('Undo approval',
                        style: AppTheme.sansBold(
                            fontSize: 13.5, color: AppTheme.signalClosed)),
                  )
                : FilledButton.icon(
                    onPressed: () {
                      provider.approveForReview();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Approved. You can post, boost and contact '
                            'candidates now.',
                            style: AppTheme.sansMedium(
                                fontSize: 13,
                                color: AppTheme.onInkOf(context)),
                          ),
                          backgroundColor: AppTheme.signalPositive,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.signalClosed,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.verified_outlined,
                        size: 17, color: Colors.white),
                    label: Text('Approve this company',
                        style: AppTheme.sansBold(
                            fontSize: 13.5, color: Colors.white)),
                  ),
          ),
          if (!verified) ...[
            const SizedBox(height: 8),
            Text(
              'Status: ${provider.company.status.label}',
              style: AppTheme.sansRegular(
                  fontSize: 11.5, color: AppTheme.inkFaintOf(context)),
            ),
          ],
        ],
      ),
    );
  }
}
