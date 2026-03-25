import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AIxKendoApp());
}

class AIxKendoApp extends StatelessWidget {
  const AIxKendoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '剣道素振り解析',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
