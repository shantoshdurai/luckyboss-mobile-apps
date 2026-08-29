import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../widgets/employer_drawer.dart';
import 'tabs/employer_dashboard_tab.dart';
import 'tabs/active_jobs_tab.dart';
import 'tabs/ats_candidates_tab.dart';
import 'tabs/company_profile_tab.dart';

class EmployerMainNavigationScreen extends StatefulWidget {
  const EmployerMainNavigationScreen({super.key});

  @override
  State<EmployerMainNavigationScreen> createState() =>
      _EmployerMainNavigationScreenState();
}

class _EmployerMainNavigationScreenState
    extends State<EmployerMainNavigationScreen> {
  int _currentIndex = 0;

  /// Which vacancy the candidates tab should open on.
  ///
  /// Set when a recruiter taps a job card. Without it, tapping "12 matching
  /// candidates" landed on whichever job happened to be first in the list —
  /// which is the wrong one every time you have more than one open.
  String? _candidateJobId;

  /// Held so a tab can open the drawer — the tabs have no Scaffold of their
  /// own above this one.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openCandidates([String? jobId]) => setState(() {
    if (jobId != null) _candidateJobId = jobId;
    _currentIndex = 2;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer:
          EmployerDrawer(onNavigate: (i) => setState(() => _currentIndex = i)),
      backgroundColor: AppTheme.paperOf(context),
      // Each tab is its own focus island — see the seeker app's navigation for
      // the full reasoning. Enter in a text field falls back to focus traversal,
      // and ungrouped traversal walks out of the form into the tab bar.
      body: FocusTraversalGroup(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            EmployerDashboardTab(
              onOpenJobs: () => setState(() => _currentIndex = 1),
              onOpenCandidates: _openCandidates,
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            ActiveJobsTab(onOpenCandidates: _openCandidates),
            AtsCandidatesTab(initialJobId: _candidateJobId),
            const CompanyProfileTab(),
          ],
        ),
      ),
      // Excluded from focus so a stray Enter can never select a tab.
      bottomNavigationBar: ExcludeFocus(
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(
              top: BorderSide(color: AppTheme.rule, width: AppTheme.hairline),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (idx) => setState(() => _currentIndex = idx),
            backgroundColor: AppTheme.surface,
            elevation: 0,
            selectedItemColor: AppTheme.ink,
            unselectedItemColor: AppTheme.inkFaint,
            selectedLabelStyle: AppTheme.meta(
              color: AppTheme.ink,
              size: 10,
              weight: FontWeight.w700,
            ),
            unselectedLabelStyle: AppTheme.meta(
              color: AppTheme.inkFaint,
              size: 10,
              weight: FontWeight.w500,
            ),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.dashboard_outlined, size: 20),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.dashboard_rounded, size: 20),
                ),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.business_center_outlined, size: 20),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.business_center_rounded, size: 20),
                ),
                label: 'Jobs',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.people_outline_rounded, size: 20),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.people_rounded, size: 20),
                ),
                label: 'ATS Pipeline',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.apartment_outlined, size: 20),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.apartment_rounded, size: 20),
                ),
                label: 'Company',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
