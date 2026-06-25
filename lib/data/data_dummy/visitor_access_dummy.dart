class VisitorAccessDummyRecord {
  const VisitorAccessDummyRecord({
    required this.visitorName,
    required this.purpose,
    required this.dateTime,
    required this.passCode,
    required this.status,
    required this.vehicleNumber,
  });

  final String visitorName;
  final String purpose;
  final DateTime dateTime;
  final String passCode;
  final String status;
  final String vehicleNumber;
}

class VisitorAccessDummy {
  const VisitorAccessDummy._();

  static const unitLabel = 'Tower Asteria - Unit A-1808';
  static const residentName = 'Nadia';
  static const defaultVisitorName = 'John Doe';
  static const defaultPhone = '+62 812-3456-7890';
  static const defaultVehicleNumber = 'B 1234 ABC';
  static const defaultPurpose = 'Visit Family';
  static const defaultVisitTime = '14:00';
  static const defaultDuration = '1 hour';
  static const defaultPassCode = 'VST-2026-00125';
  static const visitDateLabel = '08 June 2026';

  static const purposeOptions = [
    'Visit Family',
    'Business Meeting',
    'Private Guest',
    'Maintenance Visit',
  ];

  static const timeOptions = ['10:00', '14:00', '16:00', '19:00'];
  static const durationOptions = ['30 mins', '1 hour', '2 hours', 'Other'];
  static const historyFilters = [
    'All',
    'Upcoming',
    'Past',
    'Checked In',
    'Checked Out',
  ];

  static final seedHistory = [
    VisitorAccessDummyRecord(
      visitorName: 'John Doe',
      purpose: 'Visit Family',
      dateTime: DateTime(2026, 6, 8, 14, 3),
      passCode: 'VST-2026-00125',
      status: 'Checked In',
      vehicleNumber: 'B 1234 ABC',
    ),
    VisitorAccessDummyRecord(
      visitorName: 'Michael Tan',
      purpose: 'Business Meeting',
      dateTime: DateTime(2026, 6, 5, 10, 15),
      passCode: 'VST-2026-00102',
      status: 'Checked Out',
      vehicleNumber: 'B 2026 MT',
    ),
    VisitorAccessDummyRecord(
      visitorName: 'Sarah Lim',
      purpose: 'Private Guest',
      dateTime: DateTime(2026, 6, 12, 16, 0),
      passCode: 'VST-2026-00144',
      status: 'Upcoming',
      vehicleNumber: '-',
    ),
  ];
}
