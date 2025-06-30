import 'package:flutter/material.dart';
import 'package:uni_connect/features/todo/todo_page.dart';
import 'package:uni_connect/front_page.dart';
import 'package:uni_connect/splash_screen.dart';
import 'package:uni_connect/features/user/user_profile_page.dart';
import 'features/routine/routine_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/todo/todo_task.dart';
import 'features/user/user_analytics.dart';
import 'package:uni_connect/features/navigation/transition.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TodoTaskAdapter());
  await Hive.openBox<TodoTask>('todoBox');
  await Hive.openBox<TodoTask>('dailyTaskBox');
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      onGenerateRoute: (settings) {
        // Apply custom transition to all routes
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
            return NicePageRoute(
              page: const PlaceholderScreen(title: "Exam Details"),
            );
          case '/analytics':
            return NicePageRoute(page: const UserAnalyticsPage());
          case '/notices':
            return NicePageRoute(
              page: const PlaceholderScreen(title: "Notices"),
            );
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

// Placeholder for now
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(title: Text(title)),
    body: const Center(
      child: Text("Coming soon...", style: TextStyle(color: Colors.white)),
    ),
  );
}
