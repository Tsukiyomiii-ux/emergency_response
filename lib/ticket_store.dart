import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'models.dart';

class TicketStore extends ChangeNotifier {
  TicketStore._() {
    _collection.orderBy('reportedAt', descending: true).snapshots().listen((snapshot) {
      _tickets = snapshot.docs.map((doc) {
        try {
          return Ticket.fromFirestore(doc);
        } catch (e) {
          debugPrint('Skipped corrupted ticket: ${doc.id}');
          return null;
        }
      }).whereType<Ticket>().toList();
      notifyListeners();
    });
  }

  static final TicketStore instance = TicketStore._();

  final CollectionReference _collection = FirebaseFirestore.instance.collection('tickets');
  List<Ticket> _tickets = [];

  Ticket? byId(String id) {
    try {
      return _tickets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Ticket> forType(TicketType type) {
    final list = _tickets.where((t) => t.type == type).toList();

    // DYNAMIC PRIORITY QUEUE: High weight first. Ties are broken by newest time.
    list.sort((a, b) {
      final pComp = b.currentPriority.weight.compareTo(a.currentPriority.weight);
      if (pComp != 0) return pComp;

      return b.reportedAt.compareTo(a.reportedAt);
    });

    return list;
  }

Future<Ticket> create({
    required TicketType type,
    required String detail,
    required String location,
    String note = '',
  }) async {
    final now = DateTime.now();

    // ---------------------------------------------------------
    // 1. STRICT INCIDENT DEDUPLICATION (10-MINUTE CLUSTERING)
    // ---------------------------------------------------------
    try {
      final duplicate = _tickets.firstWhere((t) {
        final isSameType = t.type == type;
        final isSameLocation = t.location == location;
        final isSameCondition = t.detail == detail; 
        final isActive = t.status != TicketStatus.resolved;
        final isRecent = now.difference(t.reportedAt) <= const Duration(minutes: 10);
        
        return isSameType && isSameLocation && isSameCondition && isActive && isRecent;
      });

      await _collection.doc(duplicate.id).update({
        'verificationCount': FieldValue.increment(1),
      });
      return duplicate; 
    } catch (_) {}

    // ---------------------------------------------------------
    // 2. GEOSPATIAL DATA SETUP
    // ---------------------------------------------------------
    final targetCoords = kLocationCoords[location] ?? [50.0, 50.0];
    final targetX = targetCoords[0];
    final targetY = targetCoords[1];

    // ---------------------------------------------------------
    // 3. DYNAMIC BLAST RADIUS (GEOFENCE ALGORITHM)
    // ---------------------------------------------------------
    List<String> blastRadiusZones = [];
    
    if (detail == 'Fire' || detail == 'Suspected Bomb') {
      kLocationCoords.forEach((zoneName, coords) {
        if (zoneName != location) { 
          final dist = math.sqrt(math.pow(coords[0] - targetX, 2) + math.pow(coords[1] - targetY, 2));
          if (dist <= 15.0) { 
            blastRadiusZones.add(zoneName);
          }
        }
      });
    }

    // ---------------------------------------------------------
    // 4. SMART ROUTING & LOAD BALANCING
    // ---------------------------------------------------------
    final available = kResponders.where((r) => r.type == type).toList();
    Responder? bestResponder;
    double bestScore = double.infinity;

    for (final r in available) {
      final distance = math.sqrt(math.pow(r.x - targetX, 2) + math.pow(r.y - targetY, 2));
      final activeLoad = _tickets.where((t) => t.responder == r.name && t.status != TicketStatus.resolved).length;
      final workloadPenalty = activeLoad * 50.0;
      final finalScore = distance + workloadPenalty;

      if (finalScore < bestScore) {
        bestScore = finalScore;
        bestResponder = r;
      }
    }

    final docRef = _collection.doc();
    final ticket = Ticket(
      id: docRef.id,
      type: type,
      detail: detail,
      location: location,
      note: note,
      reportedAt: now,
      routedTo: bestResponder?.name ?? 'Unassigned',
      verificationCount: 1,
      affectedZones: blastRadiusZones, 
    );
    
    await docRef.set(ticket.toMap());

    // ---------------------------------------------------------
    // 5. AUTOMATED MULTI-AGENCY RESPONSE (CROSS-DISPATCH)
    // ---------------------------------------------------------
    // The !note.contains check acts as a circuit breaker so auto-dispatches don't infinitely trigger each other.
    if (!note.contains('[AUTO-DISPATCH]')) {
      
      // If it's a dangerous security event, automatically alert the clinic
      if (detail == 'Fight or violence' || detail == 'Suspected Bomb' || detail == 'Fire') {
        create(
          type: TicketType.medical,
          detail: 'Medical Standby',
          location: location,
          note: '[AUTO-DISPATCH] Anticipated injuries from Security incident: $detail.',
        );
      } 
      
      // If it's a severe medical event, automatically alert security to lock down the area
      else if (detail == 'Major Bleeding' || detail == 'Unconscious') {
        create(
          type: TicketType.security,
          detail: 'Security Standby',
          location: location,
          note: '[AUTO-DISPATCH] Scene control and crowd management required for Medical incident: $detail.',
        );
      }
    }

    return ticket;
  }
  
  Future<void> claim(Ticket t, String responderName) async {
    if (t.status != TicketStatus.reported) return;
    
    await _collection.doc(t.id).update({
      'status': TicketStatus.acknowledged.name,
      'responder': responderName,
      'times.${TicketStatus.acknowledged.name}': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markEnRoute(Ticket t) async {
    if (t.status != TicketStatus.acknowledged) return;
    
    await _collection.doc(t.id).update({
      'status': TicketStatus.enRoute.name,
      'times.${TicketStatus.enRoute.name}': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markResolved(Ticket t) async {
    if (t.status != TicketStatus.acknowledged &&
        t.status != TicketStatus.enRoute) {
      return;
    }
    
    await _collection.doc(t.id).update({
      'status': TicketStatus.resolved.name,
      'times.${TicketStatus.resolved.name}': DateTime.now().toIso8601String(),
    });
  }
}