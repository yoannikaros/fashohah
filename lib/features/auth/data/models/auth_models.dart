import 'dart:convert';

class AuthUser {
  final int userId;
  final String nama;
  final String? namaPanggilan;
  final String email;
  final bool isPremium;
  final String? premiumSince;
  final String? avatar;
  final String token;

  const AuthUser({
    required this.userId,
    required this.nama,
    this.namaPanggilan,
    required this.email,
    required this.isPremium,
    this.premiumSince,
    this.avatar,
    required this.token,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        userId: json['user_id'] as int,
        nama: json['nama'] as String,
        namaPanggilan: json['nama_panggilan'] as String?,
        email: json['email'] as String,
        isPremium: (json['is_premium'] == true || json['is_premium'] == 1),
        premiumSince: json['premium_since'] as String?,
        avatar: json['avatar'] as String?,
        token: json['token'] as String,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'nama': nama,
        'nama_panggilan': namaPanggilan,
        'email': email,
        'is_premium': isPremium,
        'premium_since': premiumSince,
        'avatar': avatar,
        'token': token,
      };

  String get initials {
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nama.isNotEmpty ? nama[0].toUpperCase() : '?';
  }

  AuthUser copyWith({bool? isPremium, String? premiumSince}) => AuthUser(
        userId: userId,
        nama: nama,
        namaPanggilan: namaPanggilan,
        email: email,
        isPremium: isPremium ?? this.isPremium,
        premiumSince: premiumSince ?? this.premiumSince,
        avatar: avatar,
        token: token,
      );

  static AuthUser? tryFromStorage(String? jsonStr) {
    if (jsonStr == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
