import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../widgets/lucky_ai_copilot_modal.dart';
import 'tabs/explore_jobs_tab.dart';
import 'tabs/my_applications_tab.dart';
import 'tabs/seeker_profile_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    ExploreJobsTab(),
    MyApplicationsTab(),
    SeekerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.auto_awesome, color: AppTheme.amber, size: 18),
        label: Text(
          'Ask Lucky AI',
          style: AppTheme.sansBold(fontSize: 13, color: Colors.white),
        ),
        onPressed: () => LuckyAiCopilotModal.show(context),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.borderLight)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryNavy,
          unselectedItemColor: AppTheme.textMuted,
          selectedLabelStyle: AppTheme.sansBold(fontSize: 12),
          unselectedLabelStyle: AppTheme.sansMedium(fontSize: 12),
          elevation: 0,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline_rounded),
              activeIcon: Icon(Icons.work_rounded),
              label: 'Explore Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Applications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'My Profile',
            ),
          ],
        ),
      ),
    );
  }
}