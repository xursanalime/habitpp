import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.load();
  runApp(HabitppApp(state: state));
}

class HabitppApp extends StatelessWidget {
  const HabitppApp({super.key, required this.state, this.clock = DateTime.now});

  final AppState state;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitpp',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeScreen(state: state, clock: clock),
    );
  }
}
