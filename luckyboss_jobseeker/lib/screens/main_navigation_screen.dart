import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/job_seeker_provider.dart';
import 'auth/sign_in_screen.dart';
import '../widgets/app_drawer.dart';
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

  /// Persistent reminder that this is the demo, with the way out of it.
  ///
  /// Kept as a bar rather than a one-off toast: someone shown the app for the
  /// first time should never be left wondering whether the data in front of
  /// them is theirs. Writes are refused by the server regardless — this exists
  /// so the refusal is never a surprise.
  Widget _demoBanner(BuildContext context) => Material(
        color: AppTheme.signalSourceWash,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 9, 10, 9),
            child: Row(
              children: [
                const Icon(Icons.visibility_outlined,
                    size: 16, color: AppTheme.signalSource),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Demo mode — browsing sample data. Applying and editing are off.',
                    style: AppTheme.sansMedium(
                        fontSize: 12.5, color: AppTheme.signalSource),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                    (route) => false,
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Exit',
                      style: AppTheme.sansBold(
                          fontSize: 12.5, color: AppTheme.signalSource)),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(onNavigate: _goToTab),
      body: Column(
        children: [
          if (context.watch<JobSeekerProvider>().isDemoMode) _demoBanner(context),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _tabs,
            ),
          ),
        ],
      ),
      // The 'Ask Lucky AI' FAB was a second entry point to the same assistant
      // already reachable from the header icon, and it sat on top of the job
      // cards it was covering. One route in is enough.

      bottomNavigationBar: Container(
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
    );
  }
}