class ServiceRequestRoutes {
  const ServiceRequestRoutes._();

  static const services = '/resident/services';
  static const create = '/resident/services/request/create';
  static const describe = '/resident/services/request/describe';
  static const submitted = '/resident/services/request/submitted';
  static const history = '/resident/services/request/history';
  static const assignedBase = '/resident/services/request/assigned';
  static const progressBase = '/resident/services/request/progress';
  static const completedBase = '/resident/services/request/completed';

  static const values = <String>[
    services,
    create,
    describe,
    submitted,
    history,
  ];

  static String assigned(int ticketId) => '$assignedBase/$ticketId';
  static String progress(int ticketId) => '$progressBase/$ticketId';
  static String completed(int ticketId) => '$completedBase/$ticketId';
}
