import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase/firebase_options.dart';

import 'package:provider/provider.dart';
import 'utils/font_scale.dart';
import 'utils/splash_toggle.dart';
import 'utils/data_preloader.dart';

import 'package:uni_connect/features/navigation/transition.dart';
import 'package:uni_connect/features/auth/login_page.dart';
import 'package:uni_connect/features/batchmates/batchmates_page.dart';
import 'package:uni_connect/features/chatbot/chatbot.dart';
import 'package:uni_connect/features/exams/exams.dart';
import 'package:uni_connect/features/notices/notices.dart';
import 'package:uni_connect/features/resources/resources.dart';
import 'package:uni_connect/features/settings/settings.dart';
import 'package:uni_connect/features/auth/auth_wrapper.dart';
import 'package:uni_connect/features/teachers/teachers_page.dart';
import 'package:uni_connect/features/todo/todo_page.dart';
import 'package:uni_connect/features/frontpage/front_page.dart';
import 'package:uni_connect/features/user/user_profile_page.dart';
import 'features/routine/routine_page.dart';
import 'features/todo/todo_task.dart';
import 'features/user/user_analytics.dart';
import 'features/calendar/calendar_page.dart';
import 'features/web/web_profile_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/web/web_front_page.dart';
import 'features/web/web_login_page.dart';
import 'widgets/responsive_wrapper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }

  await Hive.initFlutter();
  Hive.registerAdapter(TodoTaskAdapter());

  // Open all Hive boxes in parallel for faster startup
  await Future.wait([
    Hive.openBox<TodoTask>('todoBox'),
    Hive.openBox<TodoTask>('dailyTaskBox'),
    Hive.openBox('profileBox'),
    Hive.openBox('userBox'),
    Hive.openBox('batchmatesBox'),
    Hive.openBox('teachersBox'),
    Hive.openBox('examsBox'),
    Hive.openBox('noticesBox'),
    Hive.openBox('settingsBox'),
    Hive.openBox('goals'),
    Hive.openBox('goals_history'),
    Hive.openBox('calendarBox'),
    Hive.openBox('userCtMarksBox'),
  ]);

  // Preload critical data in background
  DataPreloader.preloadCriticalData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FontScaleProvider()),
        ChangeNotifierProvider(create: (_) => SplashToggleProvider()),
      ],
      child: const UniConnectApp(),
    ),
  );
}

class UniConnectApp extends StatelessWidget {
  const UniConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final fontScale = context.watch<FontScaleProvider>().fontScale;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Use MediaQuery to change textScaleFactor globally
        return ResponsiveWrapper(
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(fontScale)),
            child: child!,
          ),
        );
      },
      home: const AuthWrapper(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/profile':
            return NicePageRoute(
              page: kIsWeb ? const WebProfilePage() : const UserProfilePage(),
            );
          case '/frontpage':
            return NicePageRoute(
              page: kIsWeb ? const WebFrontPage() : const FrontPage(),
            );
          case '/todo':
            return NicePageRoute(page: const TodoPage());
          case '/routine':
            return NicePageRoute(page: const RoutinePage());
          case '/exam':
            return NicePageRoute(page: const ExamsPage());
          case '/batchmates':
            return NicePageRoute(page: const BatchmatesPage());
          case '/teachers':
            return NicePageRoute(page: const TeachersPage());
          case '/resources':
            return NicePageRoute(page: const ResourcesPage());
          case '/analytics':
            return NicePageRoute(page: const UserAnalyticsPage());
          case '/notices':
            return NicePageRoute(page: const NoticesPage());
          case '/login':
            return NicePageRoute(
              page: kIsWeb ? const WebLoginPage() : const LoginPage(),
            );
          case '/settings':
            return NicePageRoute(page: const SettingsPage());
          case '/chat':
            return NicePageRoute(page: const ChatbotPage());
          case '/calendar':
            return NicePageRoute(page: const CalendarPage());
          default:
            return MaterialPageRoute(
              builder: (context) =>
                  const Scaffold(body: Center(child: Text('Route not found'))),
            );
        }
      },
    );
  }
}
