import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'tabs/employer_dashboard_tab.dart';
import 'tabs/active_jobs_tab.dart';
import 'tabs/ats_candidates_tab.dart';
import 'tabs/company_profile_tab.dart';
import 'jobs/post_job_wizard_screen.dart';

class EmployerMainNavigationScreen extends StatefulWidget {
  const EmployerMainNavigationScreen({super.key});

  @override
  State<EmployerMainNavigationScreen> createState() => _EmployerMainNavigationScreenState();
}

class _EmployerMainNavigationScreenState extends State<EmployerMainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    EmployerDashboardTab(),
    ActiveJobsTab(),
    AtsCandidatesTab(),
    CompanyProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: _tabs[_currentIndex],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.ink,
        foregroundColor: AppTheme.surface,
        elevation: 2,
        icon: const Icon(Icons.add, size: 18, color: AppTheme.surface),
        label: Text('Post Job', style: AppTheme.button(color: AppTheme.surface)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostJobWizardScreen()),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.rule, width: AppTheme.hairline)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: AppTheme.surface,
          elevation: 0,
          selectedItemColor: AppTheme.ink,
          unselectedItemColor: AppTheme.inkFaint,
          selectedLabelStyle: AppTheme.meta(color: AppTheme.ink, size: 10, weight: FontWeight.w700),
          unselectedLabelStyle: AppTheme.meta(color: AppTheme.inkFaint, size: 10, weight: FontWeight.w500),
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
    );
  }
}