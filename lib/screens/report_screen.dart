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
  
  CampusSite _site = CampusSite.main;
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

  void _selectSite(CampusSite s) {
    if (s == _site) return;
    setState(() {
      _site = s;
      _location = null; // Reset specific location when switching sites
      _locationError = false;
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
        location: '${_site.label} - $_location', // Combines site + location for the responder dashboard
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
        _site = CampusSite.main;
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

  Widget _siteTile(CampusSite s, IconData icon) {
    final selected = _site == s;
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
          onTap: () => _selectSite(s),
          child: Container(
            constraints: const BoxConstraints(minHeight: 84),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28, color: selected ? AppColors.red : AppColors.navy),
                const SizedBox(height: 6),
                Text(
                  s.label,
                  style: ts(16, selected ? FontWeight.w700 : FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionChip(String label, bool isSelected, VoidCallback onTap) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(
        color: isSelected ? AppColors.red : AppColors.border,
        width: 2,
      ),
    );
    return Material(
      color: isSelected ? AppColors.redTint : Colors.white,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: ts(14, isSelected ? FontWeight.w700 : FontWeight.w600),
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
                    itemBuilder: (_, i) => _optionChip(
                      _type.details[i],
                      _detail == _type.details[i],
                      () => setState(() => _detail = _type.details[i]),
                    ),
                  ),
                  const SizedBox(height: 18),

                  _sectionLabel('3. Where?', hint: 'Required', hintColor: AppColors.red),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _siteTile(CampusSite.main, Icons.domain),
                      const SizedBox(width: 12),
                      _siteTile(CampusSite.newSite, Icons.domain_add),
                    ],
                  ),
                  const SizedBox(height: 14),
                  
                  // Specific Location Grid for the selected Campus Site
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _site.locations.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent: 44,
                    ),
                    itemBuilder: (_, i) => _optionChip(
                      _site.locations[i],
                      _location == _site.locations[i],
                      () => setState(() {
                        _location = _site.locations[i];
                        _locationError = false;
                      }),
                    ),
                  ),
                  if (_locationError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Please choose where it happened.',
                          style: ts(13, FontWeight.w600, color: AppColors.red)),
                    ),
                  const SizedBox(height: 18),

                  _sectionLabel('4. Building Floor or Room Number', hint: 'Optional'),
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