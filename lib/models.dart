import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketType { medical, security }

enum TicketStatus { reported, acknowledged, enRoute, resolved }

const kMedicalDetails = [
  'Unconscious',
  'Bleeding',
  'Difficulty breathing',
  'Chest pain',
  'Seizure',
  'Injury or fracture',
  'Allergic reaction',
  'Other',
];

const kSecurityDetails = [
  'Fight or violence',
  'Weapon sighted',
  'Intruder',
  'Theft or robbery',
  'Harassment',
  'Suspicious person',
  'Vandalism',
  'Other',
];

// TODO: replace with the real ISATU campus buildings.
const kLocations = [
  'Library',
  'Main gate',
  'Gym',
  'Canteen',
  'Parking area',
  'Administration building',
  'Clinic',
];

const _highPriority = {
  'Unconscious',
  'Bleeding',
  'Difficulty breathing',
  'Chest pain',
  'Seizure',
  'Fight or violence',
  'Weapon sighted',
  'Intruder',
};

extension TicketTypeX on TicketType {
  String get label => this == TicketType.medical ? 'Medical' : 'Security';

  String get sentTo => this == TicketType.medical
      ? 'Clinic and first-aiders'
      : 'Security guards';

  List<String> get details =>
      this == TicketType.medical ? kMedicalDetails : kSecurityDetails;
}

extension TicketStatusX on TicketStatus {
  String get label {
    switch (this) {
      case TicketStatus.reported:
        return 'Reported';
      case TicketStatus.acknowledged:
        return 'Acknowledged';
      case TicketStatus.enRoute:
        return 'En route';
      case TicketStatus.resolved:
        return 'Resolved';
    }
  }
}

class Ticket {
  Ticket({
    required this.id,
    required this.type,
    required this.detail,
    required this.location,
    required this.reportedAt,
    this.note = '',
    this.status = TicketStatus.reported,
    this.responder,
    Map<TicketStatus, DateTime>? times,
  }) : times = times ?? {TicketStatus.reported: reportedAt};

  final String id;
  final TicketType type;
  final String detail;
  final String location;
  final String note;
  final DateTime reportedAt;

  TicketStatus status;
  String? responder;

  final Map<TicketStatus, DateTime> times;

  bool get isNew => status == TicketStatus.reported;
  
  // Is it a critical issue by default?
  bool get isInherentlyHigh => _highPriority.contains(detail);
  
  // Dynamic Algorithmic Priority: True if inherently critical OR if 5 mins have passed
  bool get isHighPriority {
    if (isInherentlyHigh) return true;
    final elapsed = DateTime.now().difference(reportedAt);
    return elapsed >= const Duration(minutes: 5);
  }
  
  String get priorityLabel => isHighPriority ? 'High' : 'Medium';

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'detail': detail,
      'location': location,
      'note': note,
      'reportedAt': reportedAt.toIso8601String(),
      'status': status.name,
      'responder': responder,
      'times': times.map((k, v) => MapEntry(k.name, v.toIso8601String())),
    };
  }

  factory Ticket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timesMap = data['times'] as Map<String, dynamic>? ?? {};
    
    return Ticket(
      id: doc.id,
      type: TicketType.values.byName(data['type'] ?? 'medical'),
      detail: data['detail'] ?? '',
      location: data['location'] ?? '',
      note: data['note'] ?? '',
      reportedAt: DateTime.tryParse(data['reportedAt']?.toString() ?? '') ?? DateTime.now(),
      status: TicketStatus.values.byName(data['status'] ?? 'reported'),
      responder: data['responder'],
      times: timesMap.map((k, v) => MapEntry(
        TicketStatus.values.byName(k), 
        DateTime.tryParse(v.toString()) ?? DateTime.now(),
      )),
    );
  }
}

class Responder {
  const Responder({
    required this.loginId,
    required this.password,
    required this.name,
    required this.group,
    required this.type,
  });

  final String loginId;
  final String password;
  final String name;
  final String group;
  final TicketType type;

  String get signedInLabel => '$name ($group)';
}

const kResponders = [
  Responder(
    loginId: 'ana.clinic',
    password: 'password',
    name: 'Ana',
    group: 'Clinic',
    type: TicketType.medical,
  ),
  Responder(
    loginId: 'carlo.guard',
    password: 'password',
    name: 'Carlo',
    group: 'Security',
    type: TicketType.security,
  ),
];

Responder? authenticate(String loginId, String password) {
  for (final r in kResponders) {
    if (r.loginId == loginId && r.password == password) return r;
  }
  return null;
}

String formatTime(DateTime t, {bool seconds = false}) {
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final mm = t.minute.toString().padLeft(2, '0');
  final ss = seconds ? ':${t.second.toString().padLeft(2, '0')}' : '';
  return '$h12:$mm$ss ${t.hour < 12 ? 'AM' : 'PM'}';
}