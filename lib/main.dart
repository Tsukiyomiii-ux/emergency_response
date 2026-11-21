import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // From flutterfire configure

import 'screens/report_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const IsatuEmergencyApp());
}

class IsatuEmergencyApp extends StatelessWidget {
  const IsatuEmergencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISATU Emergency',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Students land on the report screen, no login needed.
      home: const ReportScreen(),
    );
  }
}