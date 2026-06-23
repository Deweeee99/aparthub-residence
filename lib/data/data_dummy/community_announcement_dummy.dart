class CommunityAnnouncementRecord {
  const CommunityAnnouncementRecord({
    required this.title,
    required this.category,
    required this.priority,
    required this.date,
    required this.previewMessage,
    required this.fullMessage,
    required this.affectedArea,
    required this.actionNote,
    required this.iconType,
  });

  final String title;
  final String category;
  final String priority;
  final String date;
  final String previewMessage;
  final String fullMessage;
  final String affectedArea;
  final String actionNote;
  final String iconType;
}

class CommunityAnnouncementDummy {
  const CommunityAnnouncementDummy._();

  static const filters = ['All', 'Important', 'General', 'Maintenance'];

  static const seedAnnouncements = [
    CommunityAnnouncementRecord(
      title: 'Water meter inspection this Friday',
      category: 'Maintenance',
      priority: 'Important',
      date: '23 Jun 2026',
      previewMessage:
          'Routine water meter inspection will be performed for Tower A units.',
      fullMessage:
          'Our engineering team will perform a routine water meter inspection in Tower A on Friday from 10:00 to 14:00. Please ensure maintenance staff can access the meter area if required. Temporary water pressure adjustments may happen during the inspection window.',
      affectedArea: 'Tower A resident units',
      actionNote:
          'Keep your kitchen and service access area clear in case the technical team needs quick verification.',
      iconType: 'water',
    ),
    CommunityAnnouncementRecord(
      title: 'Lobby parcel counter service update',
      category: 'General',
      priority: 'Normal',
      date: '21 Jun 2026',
      previewMessage:
          'Parcel collection hours are now extended until 22:00 every day.',
      fullMessage:
          'To improve resident convenience, the lobby parcel counter now operates until 22:00 daily. Residents collecting packages after 20:00 should present their resident QR or valid visitor authorization for assisted pickup.',
      affectedArea: 'Lobby parcel counter',
      actionNote:
          'Use the Access tab if you need to send a temporary collection pass to family or assistants.',
      iconType: 'package',
    ),
    CommunityAnnouncementRecord(
      title: 'Sky garden deep cleaning schedule',
      category: 'Maintenance',
      priority: 'Normal',
      date: '19 Jun 2026',
      previewMessage:
          'The sky garden will be unavailable during the morning deep cleaning session.',
      fullMessage:
          'A scheduled deep cleaning and landscape refresh will take place at the sky garden from 07:00 to 11:30. The area will be temporarily closed to maintain safety and cleaning quality for all residents.',
      affectedArea: 'Sky garden and seating deck',
      actionNote:
          'Please reschedule any casual meetups or photo sessions to the afternoon after the area reopens.',
      iconType: 'cleaning',
    ),
    CommunityAnnouncementRecord(
      title: 'Weekend acoustic evening confirmed',
      category: 'General',
      priority: 'Important',
      date: '18 Jun 2026',
      previewMessage:
          'Resident acoustic evening at the rooftop lounge starts at 19:30 this Saturday.',
      fullMessage:
          'The community team has confirmed this weekend acoustic evening at the rooftop lounge. Complimentary welcome drinks will be available for registered residents from 19:00, and seating will be limited to preserve comfort.',
      affectedArea: 'Rooftop lounge',
      actionNote:
          'Arrive early for the best seating and keep your resident access ready for lounge entry.',
      iconType: 'event',
    ),
  ];
}
