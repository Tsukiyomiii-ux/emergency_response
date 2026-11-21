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
    return _tickets.where((t) => t.type == type).toList();
  }

  Future<Ticket> create({
    required TicketType type,
    required String detail,
    required String location,
    String note = '',
  }) async {
    final docRef = _collection.doc();
    final ticket = Ticket(
      id: docRef.id,
      type: type,
      detail: detail,
      location: location,
      note: note,
      reportedAt: DateTime.now(),
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