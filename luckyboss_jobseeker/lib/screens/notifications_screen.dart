import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../widgets/ledger_components.dart';

/// Notifications.
///
/// Exists as a real screen even with nothing in it. The bell previously showed
/// a snackbar saying "No new notifications", which reads as a dead control —
/// the user cannot tell whether the feature is missing or simply empty. An
/// empty screen answers that question and gives somewhere for alerts to land
/// once FCM is wired (spec §56).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paperOf(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.inkOf(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications',
            style: AppTheme.sansBold(fontSize: 17, color: AppTheme.inkOf(context))),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 40),
          const LedgerEmptyState(
            headline: 'Nothing here yet',
            explanation:
                'Application updates land here — when an employer shortlists you, '
                'invites you to interview, or extends an offer.',
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      size: 19, color: AppTheme.signalSource),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What you will be told about',
                            style: AppTheme.sansBold(
                                fontSize: 13.5, color: AppTheme.inkOf(context))),
                        const SizedBox(height: 8),
                        ...const [
                          'Your application moved to shortlisted',
                          'An interview was scheduled',
                          'An offer was extended',
                          'A job matching your skills was posted',
                        ].map((line) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin:
                                        const EdgeInsets.only(top: 6, right: 9),
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                        color: AppTheme.inkFaintOf(context),
                                        shape: BoxShape.circle),
                                  ),
                                  Expanded(
                                    child: Text(line,
                                        style: AppTheme.sansRegular(
                                            fontSize: 13,
                                            color: AppTheme.inkMutedOf(context))),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
