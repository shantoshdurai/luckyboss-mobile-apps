import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      body: _tabs[_currentIndex],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: AppTheme.emeraldLight),
        label: Text('Post Job', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostJobWizardScreen()),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        selectedItemColor: AppTheme.navy,
        unselectedItemColor: AppTheme.textMuted,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.business_center_outlined), activeIcon: Icon(Icons.business_center), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'ATS Pipeline'),
          BottomNavigationBarItem(icon: Icon(Icons.apartment_outlined), activeIcon: Icon(Icons.apartment), label: 'Company'),
        ],
      ),
    );
  }
}