import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../ticket_store.dart';
import '../widgets.dart';
import 'login_screen.dart';

class ReportSentScreen extends StatelessWidget {
  const ReportSentScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context) {
    final store = TicketStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final t = store.byId(ticketId);
        
        // Prevents crash during network latency gap
        if (t == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              AppHeader(
                title: 'Report sent',
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
                      _TicketCard(ticket: t),
                      const SizedBox(height: 20),
                      Text('Status', style: ts(15, FontWeight.w700)),
                      const SizedBox(height: 12),
                      for (var i = 0; i < TicketStatus.values.length; i++)
                        _StatusStep(
                          number: i + 1,
                          status: TicketStatus.values[i],
                          time: t.times[TicketStatus.values[i]],
                        ),
                      const SizedBox(height: 8),
                      _ResponderMessage(ticket: t),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.red, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text('Make another report',
                          style: ts(17, FontWeight.w700, color: AppColors.red)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final shortId = ticket.id.length > 5 ? ticket.id.substring(0, 5).toUpperCase() : ticket.id;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ticket #$shortId', style: ts(20, FontWeight.w700)),
              StatusPill(ticket.status, fontSize: 14),
            ],
          ),
          const SizedBox(height: 14),
          InfoGrid(rows: {
            'Type': ticket.type.label,
            'Detail': ticket.detail,
            'Location': ticket.location,
            'Time': formatTime(ticket.reportedAt),
            if (ticket.note.isNotEmpty) 'Note': ticket.note,
          }),
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.number,
    required this.status,
    required this.time,
  });

  final int number;
  final TicketStatus status;
  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    final reached = time != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: reached ? AppColors.red : Colors.transparent,
              border: reached
                  ? null
                  : Border.all(color: AppColors.border, width: 2),
            ),
            child: Text(
              '$number',
              style: ts(14, FontWeight.w700,
                  color: reached ? Colors.white : AppColors.muted),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            status.label,
            style: ts(16, reached ? FontWeight.w700 : FontWeight.w500,
                color: reached ? AppColors.navy : AppColors.muted),
          ),
          const Spacer(),
          Text(
            reached ? formatTime(time!) : 'waiting',
            style: ts(14, FontWeight.w400, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ResponderMessage extends StatelessWidget {
  const _ResponderMessage({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final who = ticket.responder;
    if (who == null) {
      return Text(
        'When a responder taps "I\'ll respond", their name shows here, for example "Ana is responding".',
        style: ts(14, FontWeight.w400, color: AppColors.muted, height: 1.45),
      );
    }

    final String message;
    switch (ticket.status) {
      case TicketStatus.enRoute:
        message = '$who is on the way';
        break;
      case TicketStatus.resolved:
        message = 'Resolved by $who';
        break;
      default:
        message = '$who is responding';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.purpleBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purpleBorder, width: 2),
      ),
      child: Text(message, style: ts(16, FontWeight.w700, color: AppColors.purpleFg)),
    );
  }
}