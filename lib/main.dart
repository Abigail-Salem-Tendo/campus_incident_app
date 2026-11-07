import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
// import 'screens/auth/login_screen.dart';
import 'screens/auth_gate.dart';
import 'providers/report_provider.dart';
import 'providers/theme_provider.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Read the saved Light/Dark choice before the first screen is drawn.
  final themeProvider = await ThemeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const CampusIncidentApp(),
    ),
  );
}

class CampusIncidentApp extends StatelessWidget {
  const CampusIncidentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<ThemeProvider, ThemeMode>(
      (theme) => theme.themeMode,
    );

    return MaterialApp(
      title: 'Campus Incident App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}

/// Temporary screen replaced by the real login flow later
class FirebaseCheckScreen extends StatelessWidget {
  const FirebaseCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectId = Firebase.app().options.projectId;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Firebase connected',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(projectId, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(context.watch<AuthProvider>().status.name),
          ],
        ),
      ),
    );
  }
}
