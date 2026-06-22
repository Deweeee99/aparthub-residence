class DummyUser {
  const DummyUser({
    required this.username,
    required this.password,
    required this.route,
  });

  final String username;
  final String password;
  final String route;
}

class UserDataDummy {
  const UserDataDummy._();

  static const users = [
    DummyUser(
      username: 'resident',
      password: 'password123',
      route: '/resident',
    ),
  ];
}
