import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../services/app_settings_service.dart';
import '../widgets/lucky_ai_copilot_modal.dart';
import 'jobs/job_search_screen.dart';
import 'tabs/seeker_dashboard_tab.dart';
import 'tabs/my_applications_tab.dart';
import 'tabs/seeker_profile_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  /// Owns the Scaffold so the drawer can be opened from inside a tab.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _goToTab(int index) => setState(() => _currentIndex = index);

  /// Rebuilt each time rather than held in a const list: the dashboard needs
  /// callbacks into this state, which a const list cannot carry.
  List<Widget> get _tabs => [
    SeekerDashboardTab(
      onMenu: () => _scaffoldKey.currentState?.openDrawer(),
      onSearch: () => _goToTab(1),
      onProfile: () => _goToTab(3),
    ),
    const JobSearchScreen(),
    const MyApplicationsTab(),
    const SeekerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(onNavigate: _goToTab),
      // Each tab is its own focus island, and the nav bar is outside all of
      // them.
      //
      // This is the fix for the bug Shantosh reported twice: *"many tabs have
      // this problem of keyboard — after typing, when I press enter it goes to
      // another tab."* A text field with no `onSubmitted` falls back to default
      // focus traversal on Enter, and traversal walks the whole widget tree —
      // out of the form, into the bottom navigation, and onto a tab that then
      // takes the keypress. Grouping traversal stops focus leaving the tab it
      // started in.
      body: FocusTraversalGroup(
        child: IndexedStack(index: _currentIndex, children: _tabs),
      ),
      // Hidden when the admin has switched AI off. The server refuses the call
      // either way — this stops the candidate tapping a button that can only
      // disappoint them.
      floatingActionButton:
          _currentIndex == 0 && AppSettingsService.current.aiAssistant
          ? FloatingActionButton(
              onPressed: () => LuckyAiCopilotModal.show(context),
              backgroundColor: AppTheme.primaryFillOf(context),
              foregroundColor: AppTheme.onPrimaryFillOf(context),
              elevation: 4,
              shape: const CircleBorder(),
              tooltip: 'Ask Lucky AI',
              child: const Icon(Icons.auto_awesome, size: 24, color: Color(0xFFFFD700)),
            )
          : null,

      // Excluded from focus entirely. The tabs are reached by tapping them,
      // never by tabbing or by an Enter key escaping a form above.
      bottomNavigationBar: ExcludeFocus(
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.onInkOf(context),
            border: Border(top: BorderSide(color: AppTheme.borderLight)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.inkOf(context),
            unselectedItemColor: AppTheme.textMuted,
            selectedLabelStyle: AppTheme.sansBold(fontSize: 12),
            unselectedLabelStyle: AppTheme.sansMedium(fontSize: 12),
            elevation: 0,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                activeIcon: Icon(Icons.search_rounded),
                label: 'Search',
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
      ),
    );
  }
}
