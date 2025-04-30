import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'services/authentication_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthenticationService();

    return MaterialApp(
      title: 'TATA Retail Solutions',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF00285E), // TATA brand navy color
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFFE31837), // TATA brand red color
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home:
          authService.currentUser != null
              ? const MainNavigation()
              : const LoginScreen(),
    );
  }
}
