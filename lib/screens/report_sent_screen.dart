import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../ticket_store.dart';
import '../widgets.dart';

// ---------------------------------------------------------
// 1. THE CONFIRMATION SCREEN
// ---------------------------------------------------------
class ReportSentScreen extends StatelessWidget {
  const ReportSentScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context) {
    final shortId = ticketId.length > 5 ? ticketId.substring(0, 5).toUpperCase() : ticketId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Big visual confirmation
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.greenBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 80, color: AppColors.greenFg),
              ),
              const SizedBox(height: 32),
              
              Text(
                'Report Sent',
                style: ts(28, FontWeight.w800, color: AppColors.navy),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Text(
                'Your emergency has been routed to the closest available responder.',
                style: ts(16, FontWeight.w500, color: AppColors.muted, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Ticket ID Reference Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ticket ID: ', style: ts(15, FontWeight.w600, color: AppColors.muted)),
                    Text('#$shortId', style: ts(15, FontWeight.w800, color: AppColors.navy)),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Navigation Buttons
              PrimaryButton(
                label: 'Track Status Live',
                height: 56,
                fontSize: 17,
                radius: 12,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TicketTrackingScreen(ticketId: ticketId)),
                ),
              ),
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // Returns to the reporting form
                child: Text('Back to Home', style: ts(16, FontWeight.w700, color: AppColors.muted)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 2. THE REAL-TIME TRACKING DASHBOARD
// ---------------------------------------------------------
class TicketTrackingScreen extends StatelessWidget {
  const TicketTrackingScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context) {
    final store = TicketStore.instance;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Back Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Text('Live Tracking', style: ts(20, FontWeight.w800, color: AppColors.navy)),
                ],
              ),
            ),
            
            Expanded(
              child: ListenableBuilder(
                listenable: store,
                builder: (context, _) {
                  final t = store.byId(ticketId);
                  
                  // Show a loader briefly while Firebase syncs
                  if (t == null) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.red));
                  }

                  final shortId = t.id.length > 5 ? t.id.substring(0, 5).toUpperCase() : t.id;
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // REAL-TIME TRACKING CARD
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Ticket #$shortId', style: ts(18, FontWeight.w800)),
                                  StatusPill(t.status), // Updates live!
                                ],
                              ),
                              const SizedBox(height: 20),
                              InfoGrid(rows: {
                                'Detail': t.detail,
                                'Location': t.location,
                                'Reported': formatTime(t.reportedAt, seconds: true),
                                'Responder': t.responder != null 
                                    ? t.responder! 
                                    : (t.routedTo != null ? 'Routing to ${t.routedTo}...' : 'Pending'),
                              }),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          'Keep this screen open.\nThe status will update automatically.',
                          style: ts(14, FontWeight.w500, color: AppColors.muted, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}