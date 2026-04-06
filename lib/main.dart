import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/history_provider.dart';
import 'providers/competition_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/session_service.dart';
import 'models/auth_response.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize Notification Service
  await NotificationService().initialize();
  
  // Check for existing session
  final StudentUser? user = await SessionService.getUser();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => CompetitionProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: RaihPrestasiApp(initialUser: user),
    ),
  );
}

class RaihPrestasiApp extends StatelessWidget {
  final StudentUser? initialUser;
  
  const RaihPrestasiApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raih Prestasi Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // If user is already logged in, go to home, else login
      home: initialUser != null 
        ? HomeScreen(user: initialUser!) 
        : LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
      },
    );
  }
}
