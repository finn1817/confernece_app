// lib/router.dart

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/talk_detail_screen.dart';
import 'screens/talk_form_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/common_widgets.dart';
import 'main.dart' as main;

class AppRouter {
  static const String home            = '/';
  static const String schedule        = '/schedule';
  static const String talkDetail      = '/talk-detail';
  static const String talkForm        = '/talk-form';
  static const String userManagement  = '/users';
  static const String login           = '/login';

  // Any route in here requires isAdminGlobal == true
  static const List<String> _adminRoutes = [
    talkForm,
    userManagement,
  ];

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Admin‑only routes
    if (_adminRoutes.contains(settings.name)) {
      return _checkAdminAndGenerateRoute(settings);
    }

    // Public routes
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
        
      case home:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(builder: (_) => HomeScreen(
          toggleTheme: args?['toggleTheme'] ?? () {},
        ));

      case schedule:
        return MaterialPageRoute(builder: (_) => ScheduleScreen());

      case talkDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => TalkDetailScreen(
          talk:     args['talk'],
          isAdmin:  args['isAdmin'] ?? false,
          onUpdate: args['onUpdate'],
        ));

      case talkForm:
        // note: protected by adminRoutes
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(builder: (_) => TalkFormScreen(
          talk:   args?['talk'],
          onSave: args?['onSave'],
        ));

      default:
        return MaterialPageRoute(builder: (_) => Scaffold(
          body: Center(child: Text('No route defined for ${settings.name}')),
        ));
    }
  }

  static Route<dynamic> _checkAdminAndGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(builder: (context) {
      if (main.isAdminGlobal) {
        // Admin is allowed – dispatch normally
        switch (settings.name) {
          case talkForm:
            final args = settings.arguments as Map<String, dynamic>?;
            return TalkFormScreen(
              talk:   args?['talk'],
              onSave: args?['onSave'],
            );

          case userManagement:
            return UserManagementScreen();

          default:
            return Scaffold(
              body: Center(child: Text('No admin route for ${settings.name}')),
            );
        }
      } else {
        // Not admin – show error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pop();
          CommonWidgets.showNotificationBanner(
            context,
            message: 'Admin access required',
            isError: true,
          );
        });
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text('Admin access required'),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Go Back'),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  // Navigation helpers
  static void navigateToTalkDetail(BuildContext ctx, {
    required Map<String, dynamic> talk,
    bool isAdmin = false,
    required Function(Map<String, dynamic>) onUpdate,
  }) {
    Navigator.pushNamed(ctx, talkDetail, arguments: {
      'talk':     talk,
      'isAdmin':  isAdmin,
      'onUpdate': onUpdate,
    });
  }

  static void navigateToTalkForm(BuildContext ctx, {
    Map<String, dynamic>? talk,
    required Function(Map<String, dynamic>) onSave,
  }) {
    Navigator.pushNamed(ctx, talkForm, arguments: {
      'talk':   talk,
      'onSave': onSave,
    });
  }

  static void navigateToUserManagement(BuildContext ctx) {
    Navigator.pushNamed(ctx, userManagement);
  }
}