import 'package:flutter/material.dart';
import 'package:todo_habit_app/database_helper.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database
  await DatabaseHelper.instance.database;

  // Mark unchecked days as not done
  await DatabaseHelper.instance.markUncheckedDaysAsNotDone();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo & Habit App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}
