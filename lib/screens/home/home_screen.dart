import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../reports/reports_list_screen.dart';
import '../reports/submit_report_screen.dart';

/// Main screen after login: live list of campus reports.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus reports'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<ReportProvider>().stopListening();
              auth.logout();
            },
          ),
        ],
      ),
      body: const ReportsListScreen(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SubmitReportScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('New report'),
      ),
    );
  }
}
