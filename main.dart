// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// App-level imports
import 'app_theme.dart';
import 'router.dart';
import 'services/error_service.dart';
import 'services/firebase_service.dart';
import 'models/user.dart';

// Global admin flag used to persist login state
bool isAdminGlobal = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final errSvc = ErrorService();

  try {
    await Firebase.initializeApp();
    runApp(const ConferenceApp());
  } catch (e, st) {
    errSvc.logError('Failed to initialize app', e, st);
    runApp(ErrorApp(error: e.toString()));
  }
}

class ConferenceApp extends StatelessWidget {
  const ConferenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conference App',
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.login,
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Fallback UI if Firebase fails
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conference App Error',
      theme: ThemeData(primarySwatch: Colors.red),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                const Text(
                  'Failed to start the app',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  error,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // You can implement retry logic here if desired.
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function to check admin status during login
Future<bool> loginAdmin(String username, String password) async {
  final user = await FirebaseService().authenticate(username, password);
  if (user != null && user.isAdmin) {
    isAdminGlobal = true;
    return true;
  }
  return false;
}

/// Clears admin state
void logoutAdmin() {
  isAdminGlobal = false;
}
