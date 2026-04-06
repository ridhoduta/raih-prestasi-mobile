import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'session_service.dart';

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

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          print('Title: ${message.notification?.title}');
          print('Body: ${message.notification?.body}');
        }
      }
    });

    // 4. Get FCM Token and Sync with Server
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
