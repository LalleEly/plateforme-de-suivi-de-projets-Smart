class UserModel {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String globalRole;
  final String accessToken;
  final String refreshToken;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.globalRole,
    required this.accessToken,
    required this.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['userId'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      globalRole: json['globalRole'] ?? '',
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }

  String get fullName => '$firstName $lastName';
}