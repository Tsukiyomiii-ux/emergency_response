import 'package:flutter/material.dart';

import 'screens/report_screen.dart';
import 'theme.dart';

void main() => runApp(const IsatuEmergencyApp());

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