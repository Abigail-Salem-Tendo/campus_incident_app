import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../reports/reports_list_screen.dart';
import '../reports/submit_report_screen.dart';
import '../settings/settings_screen.dart';

/// One bottom navigation tab: its button and the screen it shows.
class _AppTab {
  const _AppTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

/// Main screen after login, with a bottom navigation bar.
/// Students get Reports | New report | Settings.
/// Staff get Reports | Settings (staff never submit reports).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isStaff = context.select<AuthProvider, bool>((a) => a.isStaff);

    final tabs = <_AppTab>[
      const _AppTab(
        label: 'Reports',
        icon: Icons.list_alt_outlined,
        selectedIcon: Icons.list_alt,
        page: _ReportsTab(),
      ),
      if (!isStaff)
        _AppTab(
          label: 'New report',
          icon: Icons.add_circle_outline,
          selectedIcon: Icons.add_circle,
          // After a report is submitted, jump back to the Reports tab.
          page: SubmitReportScreen(
            onSubmitted: () => setState(() => _index = 0),
          ),
        ),
      const _AppTab(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        page: SettingsScreen(),
      ),
    ];

    // Safety: if the tab list gets shorter, fall back to the first tab.
    final selected = _index < tabs.length ? _index : 0;

    return Scaffold(
      body: IndexedStack(
        index: selected,
        children: [for (final tab in tabs) tab.page],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

/// The reports list with its own app bar (same title as before).
class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus reports')),
      body: const ReportsListScreen(),
    );
  }
}
