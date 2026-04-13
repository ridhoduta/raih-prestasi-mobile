import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/history_provider.dart';
import 'providers/competition_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/announcement/announcement_detail_screen.dart';
import 'screens/history/achievement_detail_screen.dart';
import 'screens/history/submission_detail_screen.dart';
import 'screens/history/registration_detail_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize Notification Service
  await NotificationService().initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => CompetitionProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const RaihPrestasiApp(),
    ),
  );
}

class RaihPrestasiApp extends StatelessWidget {
  const RaihPrestasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Raih Prestasi Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/achievement_detail': (context) => AchievementDetailScreen(
              achievementId: ModalRoute.of(context)?.settings.arguments as String?,
            ),
        '/submission_detail': (context) => SubmissionDetailScreen(
              submissionId: ModalRoute.of(context)?.settings.arguments as String?,
            ),
        '/registration_detail': (context) => RegistrationDetailScreen(
              registrationId: ModalRoute.of(context)?.settings.arguments as String?,
            ),
        '/announcement_detail': (context) => AnnouncementDetailScreen(
              announcementId: ModalRoute.of(context)?.settings.arguments as String?,
            ),
      },
    );
  }
}
