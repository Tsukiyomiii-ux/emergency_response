import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';
import '../ticket_store.dart';
import '../widgets.dart';

class ResponderDashboardScreen extends StatefulWidget {
  const ResponderDashboardScreen({super.key, required this.user});

  final Responder user;

  @override
  State<ResponderDashboardScreen> createState() =>
      _ResponderDashboardScreenState();
}

class _ResponderDashboardScreenState extends State<ResponderDashboardScreen> {
  final _store = TicketStore.instance;
  String? _selectedId;
  bool _soundOn = true;
  late int _lastUnclaimed;

  int _unclaimed() =>
      _store.forType(widget.user.type).where((t) => t.isNew).length;

  @override
  void initState() {
    super.initState();
    _lastUnclaimed = _unclaimed();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    final now = _unclaimed();
    if (now > _lastUnclaimed && _soundOn) {
      SystemSound.play(SystemSoundType.alert);
    }
    _lastUnclaimed = now;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Scaffold(
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final tickets = _store.forType(user.type);

          Ticket? selected;
          for (final t in tickets) {
            if (t.id == _selectedId) selected = t;
          }
          selected ??= tickets.isEmpty ? null : tickets.first;

          return Column(
            children: [
              _buildHeader(user),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    final hPad = wide ? 32.0 : 16.0;
                    return SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStats(tickets, user.type),
                                const SizedBox(height: 20),
                                if (wide)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildTable(tickets, selected, user.type),
                                      ),
                                      const SizedBox(width: 20),
                                      SizedBox(
                                        width: 380,
                                        child: _buildDetail(selected, user),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _buildTable(tickets, selected, user.type),
                                  const SizedBox(height: 20),
                                  _buildDetail(selected, user),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Responder user) {
    return Container(
      color: AppColors.navy,
      width: double.infinity,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            runSpacing: 12,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ISATU EMERGENCY',
                      style: ts(12, FontWeight.w600,
                          color: AppColors.headerMuted, letterSpacing: 0.7)),
                  const SizedBox(height: 2),
                  Text('${user.type.label} dashboard',
                      style: ts(22, FontWeight.w700, color: Colors.white)),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 10,
                children: [
                  InkWell(
                    onTap: () => setState(() => _soundOn = !_soundOn),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _soundOn ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(_soundOn ? 'Alert sound on' : 'Alert sound off',
                              style: ts(14, FontWeight.w400, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.navyChip,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('Signed in: ${user.signedInLabel}',
                        style: ts(14, FontWeight.w600, color: Colors.white)),
                  ),
                  OutlinePillButton(
                    label: 'Log out',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(List<Ticket> tickets, TicketType type) {
    final waiting = tickets.where((t) => t.status == TicketStatus.reported).length;
    final inProgress = tickets
        .where((t) =>
            t.status == TicketStatus.acknowledged ||
            t.status == TicketStatus.enRoute)
        .length;
    final resolved = tickets.where((t) => t.status == TicketStatus.resolved).length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatCard(
          value: tickets.length,
          label: '${type.label} tickets today',
          bg: Colors.white,
          border: AppColors.border,
          fg: AppColors.navy,
          labelColor: AppColors.muted,
        ),
        _StatCard(
          value: waiting,
          label: 'Waiting for a responder',
          bg: AppColors.amberBg,
          border: AppColors.amberBorder,
          fg: AppColors.amberFg,
          labelColor: AppColors.amberFg,
        ),
        _StatCard(
          value: inProgress,
          label: 'In progress',
          bg: AppColors.purpleBg,
          border: AppColors.purpleBorder,
          fg: AppColors.purpleFg,
          labelColor: AppColors.purpleFg,
        ),
        _StatCard(
          value: resolved,
          label: 'Resolved',
          bg: AppColors.greenBg,
          border: AppColors.greenBorder,
          fg: AppColors.greenFg,
          labelColor: AppColors.greenFg,
        ),
      ],
    );
  }

  Widget _buildTable(List<Ticket> tickets, Ticket? selected, TicketType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Live ${type.label.toLowerCase()} tickets',
            style: ts(17, FontWeight.w700)),
        const SizedBox(height: 10),
        _TicketTable(
          tickets: tickets,
          selectedId: selected?.id,
          onSelect: (t) => setState(() => _selectedId = t.id),
        ),
        const SizedBox(height: 10),
        Text(
          'Only ${type.label} reports appear here. The list updates by itself. Tap a row to open its details.',
          style: ts(13, FontWeight.w400, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildDetail(Ticket? selected, Responder user) {
    if (selected == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Text('No tickets yet.',
            style: ts(15, FontWeight.w500, color: AppColors.muted)),
      );
    }
    return TicketDetailPanel(
      key: ValueKey(selected.id),
      ticket: selected,
      user: user,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.bg,
    required this.border,
    required this.fg,
    required this.labelColor,
  });

  final int value;
  final String label;
  final Color bg;
  final Color border;
  final Color fg;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: ts(26, FontWeight.w700, color: fg)),
          const SizedBox(height: 2),
          Text(label, style: ts(13, FontWeight.w400, color: labelColor)),
        ],
      ),
    );
  }
}

class _TicketTable extends StatelessWidget {
  const _TicketTable({
    required this.tickets,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Ticket> tickets;
  final String? selectedId; 
  final ValueChanged<Ticket> onSelect;

  static const _idW = 76.0;
  static const _locW = 130.0;
  static const _timeW = 100.0;
  static const _statusW = 130.0;
  static const _respW = 120.0;

  Widget _headCell(String text, {double? width}) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(text, style: ts(13, FontWeight.w600, color: AppColors.muted)),
    );
    return width == null ? Expanded(child: child) : SizedBox(width: width, child: child);
  }

  Widget _cell(Widget child, {double? width}) {
    final padded = Padding(padding: const EdgeInsets.all(14), child: child);
    return width == null ? Expanded(child: padded) : SizedBox(width: width, child: padded);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = math.max(constraints.maxWidth, 700.0);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: w,
              child: Column(
                children: [
                  Row(
                    children: [
                      _headCell('#', width: _idW),
                      _headCell('Detail'),
                      _headCell('Location', width: _locW),
                      _headCell('Time', width: _timeW),
                      _headCell('Status', width: _statusW),
                      _headCell('Responder', width: _respW),
                    ],
                  ),
                  for (var i = 0; i < tickets.length; i++)
                    _buildRow(tickets[i], isFirst: i == 0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(Ticket t, {required bool isFirst}) {
    final isNew = t.isNew;
    final isSelected = t.id == selectedId;
    final bg = isNew
        ? AppColors.redTint
        : (isSelected ? AppColors.selectedRow : Colors.white);

    final shortId = t.id.length > 5 ? t.id.substring(0, 5).toUpperCase() : t.id;

    return InkWell(
      onTap: () => onSelect(t),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            top: BorderSide(
              color: isFirst ? AppColors.border : AppColors.divider,
              width: 2,
            ),
            left: isNew
                ? const BorderSide(color: AppColors.red, width: 5)
                : BorderSide.none,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _cell(
              Text(shortId, style: ts(15, FontWeight.w700)),
              width: _idW - (isNew ? 5 : 0),
            ),
            _cell(
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(t.detail,
                      style: ts(15, isNew || isSelected ? FontWeight.w700 : FontWeight.w600)),
                  if (isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('NEW',
                          style: ts(11, FontWeight.w700, color: Colors.white)),
                    ),
                ],
              ),
            ),
            _cell(Text(t.location, style: ts(15, FontWeight.w400)), width: _locW),
            _cell(Text(formatTime(t.reportedAt), style: ts(15, FontWeight.w400)),
                width: _timeW),
            _cell(Align(alignment: Alignment.centerLeft, child: StatusPill(t.status)),
                width: _statusW),
            _cell(
              Text(
                t.responder ?? 'Unclaimed',
                style: ts(15, FontWeight.w400,
                    color: t.responder == null ? AppColors.muted : AppColors.navy),
              ),
              width: _respW,
            ),
          ],
        ),
      ),
    );
  }
}

class TicketDetailPanel extends StatefulWidget {
  const TicketDetailPanel({super.key, required this.ticket, required this.user});

  final Ticket ticket;
  final Responder user;

  @override
  State<TicketDetailPanel> createState() => _TicketDetailPanelState();
}

class _TicketDetailPanelState extends State<TicketDetailPanel> {
  static const _escalateAfter = Duration(minutes: 2);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.ticket.isNew) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _mmss(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final user = widget.user;
    final store = TicketStore.instance;

    final mine = t.responder == user.name;
    final canEnRoute = mine && t.status == TicketStatus.acknowledged;
    final canResolve = mine &&
        (t.status == TicketStatus.acknowledged || t.status == TicketStatus.enRoute);

    final shortId = t.id.length > 5 ? t.id.substring(0, 5).toUpperCase() : t.id;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.red, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ticket #$shortId', style: ts(20, FontWeight.w700)),
              StatusPill(t.status),
            ],
          ),
          const SizedBox(height: 16),
          InfoGrid(rows: {
            'Type': t.type.label,
            'Detail': t.detail,
            'Location': t.location,
            'Reported': formatTime(t.reportedAt, seconds: true),
            'Note': t.note.isEmpty ? '-' : t.note,
            'Priority': t.priorityLabel,
            'Sent to': t.type.sentTo,
          }),
          const SizedBox(height: 8),
          Text('Timeline (saved automatically)', style: ts(14, FontWeight.w700)),
          const SizedBox(height: 10),
          for (final s in TicketStatus.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.label,
                      style: ts(14, t.times.containsKey(s) ? FontWeight.w700 : FontWeight.w400,
                          color: t.times.containsKey(s) ? AppColors.navy : AppColors.muted)),
                  Text(
                    t.times[s] == null
                        ? 'not yet'
                        : formatTime(t.times[s]!, seconds: true),
                    style: ts(14, FontWeight.w400,
                        color: t.times.containsKey(s) ? AppColors.navy : AppColors.muted),
                  ),
                ],
              ),
            ),
          if (t.isNew) ...[
            const SizedBox(height: 6),
            _buildEscalationBox(t),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: t.isNew
                ? "I'll respond"
                : (t.status == TicketStatus.resolved
                    ? 'Resolved'
                    : 'Responding: ${t.responder}'),
            height: 56,
            fontSize: 17,
            radius: 12,
            onPressed: t.isNew ? () => store.claim(t, user.name) : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SecondaryAction(
                  label: 'Mark en route',
                  onPressed: canEnRoute ? () => store.markEnRoute(t) : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SecondaryAction(
                  label: 'Mark resolved',
                  onPressed: canResolve ? () => store.markResolved(t) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'These two buttons unlock after you tap "I\'ll respond".',
            style: ts(12, FontWeight.w400, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildEscalationBox(Ticket t) {
    final left = _escalateAfter - DateTime.now().difference(t.reportedAt);
    final expired = left.isNegative || left == Duration.zero;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.amberBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text.rich(
        TextSpan(
          style: ts(13, FontWeight.w400, color: AppColors.amberFg, height: 1.4),
          children: expired
              ? [
                  TextSpan(
                    text: 'Nobody claimed this ticket in 2:00. It was escalated to the next responder group.',
                    style: ts(13, FontWeight.w700, color: AppColors.amberFg, height: 1.4),
                  ),
                ]
              : [
                  const TextSpan(
                      text: 'If nobody claims this ticket in 2:00, it escalates to the next responder group. '),
                  TextSpan(
                    text: '${_mmss(left)} left.',
                    style: ts(13, FontWeight.w700, color: AppColors.amberFg, height: 1.4),
                  ),
                ],
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: enabled ? Colors.white : AppColors.bg,
          foregroundColor: AppColors.navy,
          side: BorderSide(color: enabled ? AppColors.navy : AppColors.border, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: ts(14, FontWeight.w600,
              color: enabled ? AppColors.navy : AppColors.muted),
        ),
      ),
    );
  }
}