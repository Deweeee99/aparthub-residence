class ServiceTicketRecord {
  const ServiceTicketRecord({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.assignee,
    required this.createdAt,
  });

  final String id;
  final String category;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String assignee;
  final DateTime createdAt;
}

class ServiceCategoryOption {
  const ServiceCategoryOption({
    required this.title,
    required this.subtitle,
    required this.iconCodePoint,
  });

  final String title;
  final String subtitle;
  final int iconCodePoint;
}

class ServiceRequestDummy {
  const ServiceRequestDummy._();

  static const unitLabel = 'Tower Asteria - Unit A-1808';
  static const residentName = 'Nadia';
  static const defaultTitle = 'Kitchen sink leakage';
  static const defaultDescription =
      'The kitchen sink is leaking and water keeps dripping.';
  static const defaultComment =
      'Very fast response and professional service. Thank you!';
  static const defaultCategory = 'Plumbing';
  static const defaultPriority = 'Medium';

  static const steps = [
    'Create',
    'Describe',
    'Submitted',
    'Assigned',
    'Progress',
    'Completed',
    'Rate',
    'History',
  ];

  static const priorities = ['Low', 'Medium', 'High', 'Emergency'];
  static const historyFilters = ['All', 'Open', 'Assigned', 'Progress', 'Done'];
  static const technicianName = 'John Technical';
  static const technicianRole = 'Maintenance Technician';
  static const technicianRating = '4.8 (126)';

  static const categories = [
    ServiceCategoryOption(
      title: 'Plumbing',
      subtitle: 'Water leakage, pipe repair',
      iconCodePoint: 0xe4c8,
    ),
    ServiceCategoryOption(
      title: 'Electrical',
      subtitle: 'Light, power, switch issue',
      iconCodePoint: 0xe13d,
    ),
    ServiceCategoryOption(
      title: 'Air Conditioning',
      subtitle: 'AC not cooling, maintenance',
      iconCodePoint: 0xe064,
    ),
    ServiceCategoryOption(
      title: 'Housekeeping',
      subtitle: 'Cleaning, room service',
      iconCodePoint: 0xf05d7,
    ),
    ServiceCategoryOption(
      title: 'Internet / Wi-Fi',
      subtitle: 'Connection problems',
      iconCodePoint: 0xe63e,
    ),
    ServiceCategoryOption(
      title: 'General Maintenance',
      subtitle: 'Other maintenance issues',
      iconCodePoint: 0xe30a,
    ),
  ];

  static final seedTickets = [
    ServiceTicketRecord(
      id: 'SR-2401',
      category: 'Plumbing',
      title: 'Kitchen sink leakage',
      description: 'Water keeps dripping under the kitchen sink.',
      priority: 'Medium',
      status: 'Progress',
      assignee: technicianName,
      createdAt: DateTime(2026, 6, 7, 9, 30),
    ),
    ServiceTicketRecord(
      id: 'SR-2398',
      category: 'Electrical',
      title: 'Bedroom switch issue',
      description: 'Main bedroom light switch is unstable.',
      priority: 'Low',
      status: 'Done',
      assignee: 'Dimas Engineering',
      createdAt: DateTime(2026, 6, 4, 15, 10),
    ),
    ServiceTicketRecord(
      id: 'SR-2387',
      category: 'Air Conditioning',
      title: 'AC maintenance',
      description: 'Routine AC cleaning and filter replacement.',
      priority: 'Medium',
      status: 'Done',
      assignee: 'Asteria Maintenance',
      createdAt: DateTime(2026, 5, 28, 11, 0),
    ),
  ];
}
