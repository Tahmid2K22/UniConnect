import 'package:flutter/material.dart';
import 'package:uni_connect/features/todo/todo_page.dart';
import 'package:uni_connect/front_page.dart';
import 'package:uni_connect/splash_screen.dart';
import 'package:uni_connect/features/user/user_profile_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/todo/todo_task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TodoTaskAdapter());
  await Hive.openBox<TodoTask>('todoBox');
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {
        '/profile': (_) => const UserProfilePage(),
        '/frontpage': (_) => FrontPage(),
        '/todo': (_) => const TodoPage(),
        '/exam': (_) => const PlaceholderScreen(title: "Exam Details"),
        '/analytics': (_) => const PlaceholderScreen(title: "Analytics"),
        '/notices': (_) => const PlaceholderScreen(title: "Notices"),
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
