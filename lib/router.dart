import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'talk_detail_screen.dart';
import 'talk_form_screen.dart';
import 'widgets/common_widgets.dart';
import 'main.dart' as main;

class AppRouter {
  static const String home = '/';
  static const String schedule = '/schedule';
  static const String talkDetail = '/talk-detail';
  static const String talkForm = '/talk-form';

  // Protected routes that require admin access
  static const List<String> _adminRoutes = [
    talkForm
  ];

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Check if this is an admin route
    if (_adminRoutes.contains(settings.name)) {
      return _checkAdminAndGenerateRoute(settings);
    }

    // Regular routes
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      
      case schedule:
        return MaterialPageRoute(builder: (_) => ScheduleScreen());
      
      case talkDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => TalkDetailScreen(
            talk: args['talk'],
            isAdmin: args['isAdmin'] ?? false,
            onUpdate: args['onUpdate'],
          ),
        );
      
      case talkForm:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => TalkFormScreen(
            onSave: args?['onSave'],
            talk: args?['talk'],
          ),
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  // Helper method to check admin status before generating routes
  static Route<dynamic> _checkAdminAndGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) {
        final isAdmin = main.isAdminGlobal;
        
        if (isAdmin) {
          // User is admin, proceed with route
          switch (settings.name) {
            case talkForm:
              final args = settings.arguments as Map<String, dynamic>?;
              return TalkFormScreen(
                onSave: args?['onSave'],
                talk: args?['talk'],
              );
            default:
              return Scaffold(
                body: Center(
                  child: Text('No admin route defined for ${settings.name}'),
                ),
              );
          }
        } else {
          // User is not admin, show access denied
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Go back and show error
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
      },
    );
  }

  // Helper methods to navigate with arguments
  static void navigateToTalkDetail(BuildContext context, {
    required Map<String, dynamic> talk,
    bool isAdmin = false,
    required Function(Map<String, dynamic>) onUpdate,
  }) {
    Navigator.pushNamed(
      context,
      talkDetail,
      arguments: {
        'talk': talk,
        'isAdmin': isAdmin,
        'onUpdate': onUpdate,
      },
    );
  }

  static void navigateToTalkForm(BuildContext context, {
    required Function(Map<String, dynamic>) onSave,
    Map<String, dynamic>? talk,
  }) {
    Navigator.pushNamed(
      context,
      talkForm,
      arguments: {
        'onSave': onSave,
        'talk': talk,
      },
    );
  }
}