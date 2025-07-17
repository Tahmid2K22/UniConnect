import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase/firebase_options.dart';

import 'package:uni_connect/features/navigation/transition.dart';
import 'package:uni_connect/features/auth/login_page.dart';
import 'package:uni_connect/features/batchmates/batchmates_page.dart';
import 'package:uni_connect/features/chatbot/chatbot.dart';
import 'package:uni_connect/features/exams/exams.dart';
import 'package:uni_connect/features/notices/notices.dart';
import 'package:uni_connect/features/resources/resources.dart';
import 'package:uni_connect/features/settings/settings.dart';
import 'package:uni_connect/features/splashscreen/splash_screen.dart';
import 'package:uni_connect/features/teachers/teachers_page.dart';
import 'package:uni_connect/features/todo/todo_page.dart';
import 'package:uni_connect/features/frontpage/front_page.dart';
import 'package:uni_connect/features/user/user_profile_page.dart';
import 'features/routine/routine_page.dart';
import 'features/todo/todo_task.dart';
import 'features/user/user_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  Hive.registerAdapter(TodoTaskAdapter());
  await Hive.openBox<TodoTask>('todoBox');
  await Hive.openBox<TodoTask>('dailyTaskBox');
  await Hive.openBox('profileBox');
  await Hive.openBox('userBox');
  await Hive.openBox('batchmatesBox');
  await Hive.openBox('teachersBox');
  await Hive.openBox('examsBox');
  await Hive.openBox('noticesBox');

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/profile':
            return NicePageRoute(page: const UserProfilePage());
          case '/frontpage':
            return NicePageRoute(page: FrontPage());
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
            return NicePageRoute(page: const LoginPage());
          case '/settings':
            return NicePageRoute(page: const SettingsPage());
          case '/chat':
            return NicePageRoute(page: const ChatbotPage());
          default:
            return MaterialPageRoute(
              builder: (context) =>
                  const Scaffold(body: Center(child: Text('Route not found'))),
            );
        }
      },
    ),
  );
}
