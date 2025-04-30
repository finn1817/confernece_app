import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_theme.dart';
import 'router.dart';
import 'screens/home_screen.dart';
import 'services/error_service.dart';

// Global admin state
bool isAdminGlobal = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error handling
  final errorService = ErrorService();
  
  try {
    await Firebase.initializeApp();
    runApp(ConferenceApp());
  } catch (e, stackTrace) {
    errorService.logError('Failed to initialize app', e, stackTrace);
    runApp(ErrorApp(error: e.toString()));
  }
}

class ConferenceApp extends StatefulWidget {
  @override
  _ConferenceAppState createState() => _ConferenceAppState();
}

class _ConferenceAppState extends State<ConferenceApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conference App',
      theme: AppTheme.lightTheme,
      home: HomeScreen(),
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({required this.error});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conference App Error',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
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
                    // This would restart the app in a real scenario
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

// Utility function to check admin credentials
bool checkAdminCredentials(String username, String password) {
  return username == 'Admin' && password == 'CSIT425';
}
