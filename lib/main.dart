import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'services/excel_service.dart';
import 'services/notification_service.dart';
import 'services/plant_repository.dart';
import 'services/user_service.dart';
import 'theme/skeuo_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Production Error Handler: Prevent unexpected exceptions from crashing the app
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    return true;
  };
  
  // Initialize notification service
  await NotificationService().initialize();

  // Load user data, excel species database, and plant repository at app startup
  final userService = UserService();
  await userService.loadUserData();

  final excelService = ExcelService();
  await excelService.loadSpeciesDatabase();

  final plantRepo = PlantRepository();
  await plantRepo.loadLocalData();

  // Check due plant notifications
  await NotificationService().checkAndNotifyDuePlants(plantRepo.plants);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpryFlora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: SkeuoTheme.primaryGreen,
          primary: SkeuoTheme.primaryGreen,
          secondary: SkeuoTheme.funYellow,
        ),
        scaffoldBackgroundColor: SkeuoTheme.background,
        textTheme: GoogleFonts.nunitoTextTheme(),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}