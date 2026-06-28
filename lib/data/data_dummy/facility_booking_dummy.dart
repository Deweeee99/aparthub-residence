class FacilityBookingRecord {
  const FacilityBookingRecord({
    required this.id,
    required this.facility,
    required this.location,
    required this.date,
    required this.slot,
    required this.guestCount,
    required this.status,
    required this.notes,
  });

  final String id;
  final String facility;
  final String location;
  final DateTime date;
  final String slot;
  final int guestCount;
  final String status;
  final String notes;

  FacilityBookingRecord copyWith({String? status}) {
    return FacilityBookingRecord(
      id: id,
      facility: facility,
      location: location,
      date: date,
      slot: slot,
      guestCount: guestCount,
      status: status ?? this.status,
      notes: notes,
    );
  }
}

class FacilityOption {
  const FacilityOption({
    required this.name,
    required this.subtitle,
    required this.location,
    required this.capacity,
  });

  final String name;
  final String subtitle;
  final String location;
  final String capacity;
}

class FacilitySlotOption {
  const FacilitySlotOption({required this.slot, required this.status});

  final String slot;
  final String status;
}

class FacilityBookingDummy {
  const FacilityBookingDummy._();

  static const filters = ['Upcoming', 'Past'];

  static const facilities = [
    FacilityOption(
      name: 'Gym',
      subtitle: 'Private workout session with resident access.',
      location: 'Level 3 Wellness Area',
      capacity: 'Max 4 residents',
    ),
    FacilityOption(
      name: 'Tennis Court',
      subtitle: 'Reserve your match time with clear availability.',
      location: 'Level 4 Sports Deck',
      capacity: 'Max 4 guests',
    ),
    FacilityOption(
      name: 'Meeting Room',
      subtitle: 'A quiet private space for meetings and calls.',
      location: 'Level 2 Business Lounge',
      capacity: 'Max 8 guests',
    ),
    FacilityOption(
      name: 'Function Hall',
      subtitle: 'Premium hall for family and community events.',
      location: 'Ground Floor',
      capacity: 'Max 30 guests',
    ),
    FacilityOption(
      name: 'Sky Lounge',
      subtitle: 'Rooftop lounge with skyline view.',
      location: 'Rooftop',
      capacity: 'Max 12 guests',
    ),
  ];

  static const slots = [
    FacilitySlotOption(slot: '07:00 - 09:00', status: 'Available'),
    FacilitySlotOption(slot: '09:00 - 11:00', status: 'Available'),
    FacilitySlotOption(slot: '11:00 - 13:00', status: 'Booked'),
    FacilitySlotOption(slot: '13:00 - 15:00', status: 'Available'),
    FacilitySlotOption(slot: '15:00 - 17:00', status: 'Available'),
    FacilitySlotOption(slot: '19:00 - 21:00', status: 'Available'),
  ];

  static final seedBookings = [
    FacilityBookingRecord(
      id: 'BK-2401',
      facility: 'Gym',
      location: 'Level 3 Wellness Area',
      date: DateTime(2026, 6, 29),
      slot: '07:00 - 09:00',
      guestCount: 2,
      status: 'Approved',
      notes: 'Morning workout session.',
    ),
    FacilityBookingRecord(
      id: 'BK-2402',
      facility: 'Sky Lounge',
      location: 'Rooftop',
      date: DateTime(2026, 7, 2),
      slot: '19:00 - 21:00',
      guestCount: 4,
      status: 'Waiting Approval',
      notes: 'Small family gathering.',
    ),
    FacilityBookingRecord(
      id: 'BK-2398',
      facility: 'Tennis Court',
      location: 'Level 4 Sports Deck',
      date: DateTime(2026, 6, 16),
      slot: '15:00 - 17:00',
      guestCount: 2,
      status: 'Completed',
      notes: 'Weekly tennis practice.',
    ),
  ];
}
