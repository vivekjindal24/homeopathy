import '../../core/utils/constants.dart';

/// Domain model for an authenticated user with role.
class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String? ?? 'Unknown',
      role: UserRoleX.fromString(json['role'] as String? ?? 'patient'),
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'full_name': fullName,
        'role': role.name,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
      };
  UserModel copyWith({
    String? email,
    String? phone,
    String? fullName,
    UserRole? role,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

