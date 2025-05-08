// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'router.dart';
import 'screens/home_screen.dart';

// Global state for admin status
bool isAdminGlobal = false;

// Global reference to app state for theme toggling
late _ConferenceAppState _appState;

// Admin authentication functions
Future<bool> loginAdmin(String username, String password) async {
  // Admin authentication for the conference app
  if (username == 'admin' && password == 'password') {
    isAdminGlobal = true;
    
    // Save admin status in preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdmin', true);
    
    return true;
  }
  return false;
}

void logoutAdmin() async {
  isAdminGlobal = false;
  
  // Clear admin status
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isAdmin', false);
}

// Global function to toggle theme that can be called from anywhere
void toggleTheme() {
  _appState.toggleTheme();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Load theme and admin preferences
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  final isAdmin = prefs.getBool('isAdmin') ?? false;
  
  // Set global admin status
  isAdminGlobal = isAdmin;
  
  runApp(ConferenceApp(isDarkMode: isDarkMode));
}

class ConferenceApp extends StatefulWidget {
  final bool isDarkMode;
  
  const ConferenceApp({Key? key, this.isDarkMode = false}) : super(key: key);

  @override
  _ConferenceAppState createState() => _ConferenceAppState();
}

class _ConferenceAppState extends State<ConferenceApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _appState = this; // Store reference to this state
  }

  void toggleTheme() async {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    
    // Save theme preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conference App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      initialRoute: AppRouter.login,
      onGenerateRoute: (settings) {
        // Special case for home route to pass the theme toggle
        if (settings.name == AppRouter.home) {
          return MaterialPageRoute(
            builder: (_) => HomeScreen(
              toggleTheme: toggleTheme,
            ),
          );
        }
        // For all other routes
        return AppRouter.generateRoute(settings);
      },
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          // Ensure consistent text scaling
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}