class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.roleId,
    required this.role,
    this.qrCode,
  });

  final int id;
  final String fullName;
  final String email;
  final int roleId;
  final String role;
  final String? qrCode;

  bool get isStudent => roleId == 2;
  bool get isScanner => roleId == 3;
  bool get isAlumni => roleId == 4;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : json;
    return UserModel(
      id: int.tryParse(user['id']?.toString() ?? '') ?? 0,
      fullName: displayName(user, fallback: 'BITS User'),
      email: user['email']?.toString() ?? '',
      roleId: int.tryParse(user['role_id']?.toString() ?? '') ?? 0,
      role: user['role']?.toString() ?? '',
      qrCode: user['qr_code']?.toString(),
    );
  }
}

String displayName(Map<String, dynamic> json, {String fallback = 'Student'}) {
  final nestedUser = json['user'] is Map
      ? Map<String, dynamic>.from(json['user'] as Map)
      : const <String, dynamic>{};
  final values = [
    json['full_name'],
    json['name'],
    json['student_name'],
    nestedUser['full_name'],
    nestedUser['name'],
    _joined([json['first_name'], json['last_name']]),
    _joined([json['firstname'], json['lastname']]),
    _joined([nestedUser['first_name'], nestedUser['last_name']]),
    _joined([nestedUser['firstname'], nestedUser['lastname']]),
  ];

  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null &&
        text.isNotEmpty &&
        text.toLowerCase() != 'null' &&
        !text.toLowerCase().contains('n/a')) {
      return text;
    }
  }

  return fallback;
}

String? _joined(List<Object?> values) {
  final parts = values
      .map((value) => value?.toString().trim() ?? '')
      .where((value) => value.isNotEmpty && value.toLowerCase() != 'null')
      .toList();
  return parts.isEmpty ? null : parts.join(' ');
}
