import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'talk_detail_screen.dart';
import 'talk_form_screen.dart';

class AppRouter {
  static const String home = '/';
  static const String schedule = '/schedule';
  static const String talkDetail = '/talk-detail';
  static const String talkForm = '/talk-form';

  static Route<dynamic> generateRoute(RouteSettings settings) {
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
  }) {
    Navigator.pushNamed(
      context,
      talkForm,
      arguments: {
        'onSave': onSave,
      },
    );
  }
}