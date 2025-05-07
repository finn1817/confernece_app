// lib/main.dart

// flutter imports
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// app-level imports
import 'app_theme.dart'; // custom themes
import 'router.dart'; // app route definitions
import 'screens/home_screen.dart'; // home page of the app
import 'services/error_service.dart'; // logs startup errors
import 'services/firebase_service.dart'; // handles firebase auth/firestore
import 'models/user.dart'; // basic user model class
// models is unused but was used origionally to create a user object from the firebase data

// global admin flag used to persist login state (simplified for now)
bool isAdminGlobal = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // makes sure flutter engine is ready
  final errSvc = ErrorService(); // helper to log any init errors

  try {
    await Firebase.initializeApp(); // connect to Firebase before running
    runApp(ConferenceApp()); // start the actual app
  } catch (e, st) {
    errSvc.logError('Failed to initialize app', e, st); // log crash info
    runApp(ErrorApp(error: e.toString())); // show fallback error UI
  }
}

// root widget for the actual app
class ConferenceApp extends StatefulWidget {
  @override
  _ConferenceAppState createState() => _ConferenceAppState();
}

class _ConferenceAppState extends State<ConferenceApp> {
  ThemeMode _themeMode = ThemeMode.light; // start in light mode

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conference App',
      theme: AppTheme.lightTheme, // default light mode
      darkTheme: AppTheme.darkTheme, // dark mode
      themeMode: _themeMode, // ← use dynamic theme mode
      home: HomeScreen(toggleTheme: _toggleTheme), // starting page
      onGenerateRoute: AppRouter.generateRoute, // handles named navigation
      debugShowCheckedModeBanner: false, // hides flutter debug banner
    );
  }
}

// basic error 'fallback' UI shown if firebase isn't working as it should (no internet can also cause this)
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({ required this.error });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conference App Error',
      theme: ThemeData(primarySwatch: Colors.red), // error color theme
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
                  error, // shows actual firebase error message
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // could retry firebase init later if needed
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

/// helper used during login to verify admin accounts from firestore db
Future<bool> loginAdmin(String username, String password) async {
  final user = await FirebaseService().authenticate(username, password);
  if (user != null && user.isAdmin) {
    isAdminGlobal = true;
    return true;
  }
  return false;
}

/// resets admin state (for logout)
void logoutAdmin() {
  isAdminGlobal = false;
}
