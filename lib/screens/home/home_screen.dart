import 'package:campus_incident_app/screens/reports/submit_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../reports/submit_report_screen.dart';

import '../../providers/auth_provider.dart';

/// Placeholder. Replaced by the real report list on Day 5.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Signed in as ${profile?.name ?? ''}\nRole: ${profile?.role.name ?? ''}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
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
