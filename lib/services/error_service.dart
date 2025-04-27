import 'dart:async';
import 'package:flutter/foundation.dart';

class ErrorService {
  // Singleton pattern
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();
  
  // Log an error
  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final errorString = '$timestamp - $message ${error != null ? '- $error' : ''}';
    
    // Print to console in debug mode
    if (kDebugMode) {
      print('ERROR: $errorString');
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
  }
  
  // Handle exceptions and errors with a default value
  Future<T> handleErrorWithDefault<T>(
    Future<T> Function() operation, 
    String contextMessage,
    T defaultValue
  ) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      logError('$contextMessage: $e', e, stackTrace);
      return defaultValue;
    }
  }
  
  // Check if Firebase is properly configured
  bool isFirebaseError(dynamic error) {
    if (error is String) {
      return error.contains('PERMISSION_DENIED') || 
             error.contains('not been used in project') ||
             error.contains('is disabled');
    }
    return false;
  }
  
  // Get a user-friendly error message
  String getFirebaseErrorMessage() {
    return 'Firebase service is not configured properly. Please make sure Firebase is set up correctly.';
  }
}