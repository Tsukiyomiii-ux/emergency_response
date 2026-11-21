import 'package:flutter/foundation.dart';

import 'models.dart';

/// Shared in-memory "backend" so the student app and the responder dashboards
/// stay in sync during the demo. Swap the methods for Firebase / REST calls
/// later; the screens only talk to this class.
class TicketStore extends ChangeNotifier {
  TicketStore._() {
    _tickets.addAll(_seed());
  }

  static final TicketStore instance = TicketStore._();

  final List<Ticket> _tickets = [];
  int _nextId = 14; // wireframe tickets go up to #13

  Ticket? byId(int id) {
    for (final t in _tickets) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Newest first, only the tickets for one dashboard.
  List<Ticket> forType(TicketType type) {
    final list = _tickets.where((t) => t.type == type).toList();
    list.sort((a, b) => b.id.compareTo(a.id));
    return list;
  }

  Ticket create({
    required TicketType type,
    required String detail,
    required String location,
    String note = '',
  }) {
    final ticket = Ticket(
      id: _nextId++,
      type: type,
      detail: detail,
      location: location,
      note: note,
      reportedAt: DateTime.now(), // time is recorded automatically
    );
    _tickets.add(ticket);
    notifyListeners();
    return ticket;
  }

  /// "I'll respond"
  void claim(Ticket t, String responderName) {
    if (t.status != TicketStatus.reported) return;
    t.status = TicketStatus.acknowledged;
    t.responder = responderName;
    t.times[TicketStatus.acknowledged] = DateTime.now();
    notifyListeners();
  }

  void markEnRoute(Ticket t) {
    if (t.status != TicketStatus.acknowledged) return;
    t.status = TicketStatus.enRoute;
    t.times[TicketStatus.enRoute] = DateTime.now();
    notifyListeners();
  }

  void markResolved(Ticket t) {
    if (t.status != TicketStatus.acknowledged &&
        t.status != TicketStatus.enRoute) {
      return;
    }
    t.status = TicketStatus.resolved;
    t.times[TicketStatus.resolved] = DateTime.now();
    notifyListeners();
  }
}

List<Ticket> _seed() {
  final now = DateTime.now();
  DateTime at(int h, int m) => DateTime(now.year, now.month, now.day, h, m);
  // The two "NEW" tickets are 72 seconds old so the 2:00 escalation timer
  // starts at about 0:48 left, like the wireframe.
  final justNow = now.subtract(const Duration(seconds: 72));

  return [
    Ticket(
      id: 8,
      type: TicketType.security,
      detail: 'Suspicious person',
      location: 'Parking area',
      reportedAt: at(9, 15),
      status: TicketStatus.resolved,
      responder: 'Dante',
      times: {
        TicketStatus.reported: at(9, 15),
        TicketStatus.acknowledged: at(9, 16),
        TicketStatus.enRoute: at(9, 17),
        TicketStatus.resolved: at(9, 25),
      },
    ),
    Ticket(
      id: 9,
      type: TicketType.medical,
      detail: 'Difficulty breathing',
      location: 'Canteen',
      reportedAt: at(9, 20),
      status: TicketStatus.resolved,
      responder: 'Ana',
      times: {
        TicketStatus.reported: at(9, 20),
        TicketStatus.acknowledged: at(9, 21),
        TicketStatus.enRoute: at(9, 22),
        TicketStatus.resolved: at(9, 30),
      },
    ),
    Ticket(
      id: 10,
      type: TicketType.security,
      detail: 'Theft or robbery',
      location: 'Canteen',
      reportedAt: at(9, 32),
      status: TicketStatus.enRoute,
      responder: 'Carlo',
      times: {
        TicketStatus.reported: at(9, 32),
        TicketStatus.acknowledged: at(9, 33),
        TicketStatus.enRoute: at(9, 34),
      },
    ),
    Ticket(
      id: 11,
      type: TicketType.medical,
      detail: 'Bleeding',
      location: 'Gym',
      reportedAt: at(9, 38),
      status: TicketStatus.enRoute,
      responder: 'Ben',
      times: {
        TicketStatus.reported: at(9, 38),
        TicketStatus.acknowledged: at(9, 39),
        TicketStatus.enRoute: at(9, 40),
      },
    ),
    Ticket(
      id: 12,
      type: TicketType.medical,
      detail: 'Unconscious',
      location: 'Library',
      note: 'Student fainted near the entrance',
      reportedAt: justNow,
    ),
    Ticket(
      id: 13,
      type: TicketType.security,
      detail: 'Fight or violence',
      location: 'Main gate',
      note: 'Two students fighting near the gate',
      reportedAt: justNow,
    ),
  ];
}
