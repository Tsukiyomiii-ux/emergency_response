import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../ticket_store.dart';
import '../widgets.dart';
import 'login_screen.dart';
import 'report_sent_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _noteCtrl = TextEditingController();

  TicketType _type = TicketType.medical;
  String _detail = TicketType.medical.details.first;
  String? _location;
  bool _locationError = false;
  bool _isSending = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _selectType(TicketType t) {
    if (t == _type) return;
    setState(() {
      _type = t;
      _detail = t.details.first;
    });
  }

  Future<void> _send() async {
    if (_location == null) {
      setState(() => _locationError = true);
      return;
    }
    
    setState(() => _isSending = true);

    try {
      final ticket = await TicketStore.instance.create(
        type: _type,
        detail: _detail,
        location: _location!,
        note: _noteCtrl.text.trim(),
      );
      
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReportSentScreen(ticketId: ticket.id)),
      );
      
      if (!mounted) return;
      setState(() {
        _type = TicketType.medical;
        _detail = _type.details.first;
        _location = null;
        _locationError = false;
        _noteCtrl.clear();
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Widget _sectionLabel(String title, {String? hint, Color? hintColor}) {
    return Text.rich(
      TextSpan(
        text: title,
        style: ts(15, FontWeight.w700),
        children: [
          if (hint != null)
            TextSpan(
              text: ' $hint',
              style: ts(15, FontWeight.w500, color: hintColor ?? AppColors.muted),
            ),
        ],
      ),
    );
  }

  Widget _typeTile(TicketType t, IconData icon) {
    final selected = _type == t;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selected ? AppColors.red : AppColors.border,
        width: selected ? 3 : 2,
      ),
    );
    return Expanded(
      child: Material(
        color: selected ? AppColors.redTint : Colors.white,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: () => _selectType(t),
          child: Container(
            constraints: const BoxConstraints(minHeight: 84),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28, color: selected ? AppColors.red : AppColors.navy),
                const SizedBox(height: 6),
                Text(
                  t.label,
                  style: ts(16, selected ? FontWeight.w700 : FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailChip(String label) {
    final selected = _detail == label;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(
        color: selected ? AppColors.red : AppColors.border,
        width: 2,
      ),
    );
    return Material(
      color: selected ? AppColors.redTint : Colors.white,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: () => setState(() => _detail = label),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: ts(14, selected ? FontWeight.w700 : FontWeight.w600),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Report an emergency',
            trailing: OutlinePillButton(
              label: 'Log in',
              icon: Icons.person_outline,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('1. What happened?'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _typeTile(TicketType.medical, Icons.local_hospital_outlined),
                      const SizedBox(width: 12),
                      _typeTile(TicketType.security, Icons.shield_outlined),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _sectionLabel('2. What exactly?', hint: 'Tap one'),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _type.details.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent: 44,
                    ),
                    itemBuilder: (_, i) => _detailChip(_type.details[i]),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'The options change with Medical or Security, so the responder knows what to prepare before arriving.',
                    style: ts(12, FontWeight.w400, color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  _sectionLabel('3. Where?', hint: 'Required', hintColor: AppColors.red),
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _locationError ? AppColors.red : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _location,
                        isExpanded: true,
                        hint: Text('Select a campus building',
                            style: ts(16, FontWeight.w500, color: AppColors.muted)),
                        style: ts(16, FontWeight.w500),
                        items: [
                          for (final loc in kLocations)
                            DropdownMenuItem(value: loc, child: Text(loc)),
                        ],
                        onChanged: (v) => setState(() {
                          _location = v;
                          _locationError = false;
                        }),
                      ),
                    ),
                  ),
                  if (_locationError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Please choose where it happened.',
                          style: ts(13, FontWeight.w600, color: AppColors.red)),
                    ),
                  const SizedBox(height: 18),
                  _sectionLabel('4. Short note', hint: 'Optional'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    style: ts(15, FontWeight.w400),
                    decoration: appInput(),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: _isSending ? 'Sending...' : 'Send report', 
                    onPressed: _isSending ? null : _send,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Time of report is recorded automatically.',
                    style: ts(13, FontWeight.w400, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}