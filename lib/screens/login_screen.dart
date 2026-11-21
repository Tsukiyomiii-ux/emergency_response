import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'responder_dashboard_screen.dart';

/// Wireframe 3. The account decides which dashboard opens.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Prefilled like the wireframe so the demo is one tap.
  final _idCtrl = TextEditingController(text: '');
  final _pwCtrl = TextEditingController(text: '');
  String? _error;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  void _login() {
    final user = authenticate(_idCtrl.text.trim(), _pwCtrl.text);
    if (user == null) {
      setState(() => _error = 'Wrong ID or password.');
      return;
    }
    // Keep the report screen at the bottom of the stack so "Log out" can pop.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => ResponderDashboardScreen(user: user)),
      (route) => route.isFirst,
    );
  }

  Widget _fieldLabel(String text) =>
      Text(text, style: ts(15, FontWeight.w700));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(title: 'Responder log in'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For clinic staff, first-aiders and security guards only. Students do not need to log in to send a report.',
                    style: ts(14, FontWeight.w400, color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  _fieldLabel('Responder ID or email'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _idCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: ts(16, FontWeight.w500),
                    decoration: appInput(),
                  ),
                  const SizedBox(height: 18),
                  _fieldLabel('Password'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pwCtrl,
                    obscureText: true,
                    style: ts(16, FontWeight.w500),
                    decoration: appInput(),
                    onSubmitted: (_) => _login(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!,
                        style: ts(14, FontWeight.w600, color: AppColors.red)),
                  ],
                  const SizedBox(height: 18),
                  PrimaryButton(label: 'Log in', onPressed: _login),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: ts(13, FontWeight.w400, color: AppColors.muted, height: 1.5),
                        children: [
                          const TextSpan(
                              text: 'After logging in, the account decides the screen: '),
                          TextSpan(
                              text: 'Medical dashboard',
                              style: ts(13, FontWeight.w700)),
                          const TextSpan(text: ' for clinic staff and first-aiders, '),
                          TextSpan(
                              text: 'Security dashboard',
                              style: ts(13, FontWeight.w700)),
                          const TextSpan(text: ' for guards.'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Demo helper. Delete before real use.
                  Text(
                    'Demo accounts: main.clinic, new.clinic (Medical) | main.guard, new.guard (Security). Password: password',
                    style: ts(12, FontWeight.w400, color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Back to report an emergency',
                    style: ts(15, FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
