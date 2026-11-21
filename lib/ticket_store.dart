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
    // 1. Get base coordinates for the emergency
    final targetCoords = kLocationCoords[location] ?? [50.0, 50.0];
    final targetX = targetCoords[0];
    final targetY = targetCoords[1];

    // 2. Find available responder teams for this type
    final available = kResponders.where((r) => r.type == type).toList();

    // 3. SMART ALGORITHM: Geospatial Proximity + Load Balancing
    Responder? bestResponder;
    double bestScore = double.infinity;

    for (final r in available) {
      // Calculate raw physical distance (Euclidean formula)
      final distance = math.sqrt(math.pow(r.x - targetX, 2) + math.pow(r.y - targetY, 2));

      // Count how many active tickets this specific responder is currently handling
      final activeLoad = _tickets.where((t) => t.responder == r.name && t.status != TicketStatus.resolved).length;

      // The Backup Logic: Add a massive distance penalty (50 units) for every active ticket.
      // If they are busy, the algorithm considers them "further away" and routes to the backup.
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
      reportedAt: DateTime.now(),
      routedTo: bestResponder?.name ?? 'Unassigned',
    );
    
    await docRef.set(ticket.toMap());
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