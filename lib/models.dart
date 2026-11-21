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

  final int id;
  final TicketType type;
  final String detail;
  final String location;
  final String note;
  final DateTime reportedAt;

  TicketStatus status;
  String? responder;

  /// When each status was reached (used by the timelines).
  final Map<TicketStatus, DateTime> times;

  bool get isNew => status == TicketStatus.reported;
  bool get isHighPriority => _highPriority.contains(detail);
  String get priorityLabel => isHighPriority ? 'High' : 'Normal';
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

  /// The account decides which dashboard opens.
  final TicketType type;

  String get signedInLabel => '$name ($group)';
}

// Demo accounts for the hackathon. Replace with real auth later.
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

/// "9:41 AM" or, with [seconds], "9:41:05 AM".
String formatTime(DateTime t, {bool seconds = false}) {
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final mm = t.minute.toString().padLeft(2, '0');
  final ss = seconds ? ':${t.second.toString().padLeft(2, '0')}' : '';
  return '$h12:$mm$ss ${t.hour < 12 ? 'AM' : 'PM'}';
}
