import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'session_service.dart';
import '../main.dart';

/// Top-level function to handle background messages.
/// This MUST be a top-level function (not a class method) for Firebase Messaging to work.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp()` first.
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
    print("Message data: ${message.data}");
    print("Message notification: ${message.notification?.title}");
  }
}

class NotificationService {
  // Private constructor
  NotificationService._internal();

  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Initialize the notification service.
  Future<void> initialize() async {
    // 1. Request permission (especially for iOS and Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // 2. Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Setup foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }
    });

    // 4. Handle notification clicks when app is in background/foreground
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
    });

    // 5. Check for initial message (app opened from terminated state)
    _setupInteractedMessage();

    // 6. Get FCM Token and Sync with Server
    String? token = await getToken();
    if (kDebugMode) {
      print("=================================================");
      print("FCM DEVICE TOKEN: $token");
      print("=================================================");
    }
    
    if (token != null) {
      await syncTokenWithServer(token);
    }
  }

  /// Handle navigation based on notification data.
  void _handleNotificationClick(RemoteMessage message) {
    if (kDebugMode) {
      print("Notification clicked with data: ${message.data}");
    }

    final String? screen = message.data['screen'];
    final String? id = message.data['id'];

    if (screen != null && id != null) {
      // Map screen names from data to actual routes
      switch (screen) {
        case 'achievement_detail':
          navigatorKey.currentState?.pushNamed('/achievement_detail', arguments: id);
          break;
        case 'submission_detail':
          navigatorKey.currentState?.pushNamed('/submission_detail', arguments: id);
          break;
        case 'registration_detail':
          navigatorKey.currentState?.pushNamed('/registration_detail', arguments: id);
          break;
        case 'announcement_detail':
          navigatorKey.currentState?.pushNamed('/announcement_detail', arguments: id);
          break;
        default:
          if (kDebugMode) print("Unknown screen: $screen");
      }
    }
  }

  /// Check for initial message when the app starts.
  Future<void> _setupInteractedMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
    }
  }

  /// Synchronize the FCM token with the backend server if the user is logged in.
  Future<void> syncTokenWithServer([String? token]) async {
    try {
      final user = await SessionService.getUser();
      if (user != null) {
        final currentToken = token ?? await getToken();
        if (currentToken != null) {
          await ApiService().registerFcmToken(user.id, currentToken);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error syncing FCM token with server: $e");
      }
    }
  }

  /// Get the device token.
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        print("Error getting FCM token: $e");
      }
      return null;
    }
  }
}
