import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/enums/user_role.dart';

/// Domain entity representing the authenticated account.
///
/// Mirrors the backend `UserResponse` schema (see
/// `contracts/identity.openapi.yaml`). JSON helpers support both decoding API
/// responses and caching the user in secure storage for instant startup.
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.role = UserRole.candidate,
    this.city,
    this.country,
    this.address,
    this.profileImageUrl,
    this.termsAccepted = false,
    this.emailVerified = false,
    this.active = true,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final UserRole role;
  final String? city;
  final String? country;
  final String? address;
  final String? profileImageUrl;
  final bool termsAccepted;
  final bool emailVerified;
  final bool active;

  String get fullName => '$firstName $lastName';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: (json['id'] ?? '').toString(),
    firstName: (json['firstName'] ?? '') as String,
    lastName: (json['lastName'] ?? '') as String,
    email: (json['email'] ?? '') as String,
    phone: json['phoneNumber'] as String?,
    role: userRoleFromWire(json['role'] as String?),
    city: json['city'] as String?,
    country: json['country'] as String?,
    address: json['address'] as String?,
    profileImageUrl: json['profileImageUrl'] as String?,
    termsAccepted: (json['termsAccepted'] ?? false) as bool,
    emailVerified: (json['emailVerified'] ?? false) as bool,
    active: (json['active'] ?? true) as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phoneNumber': phone,
    'role': role.wireValue,
    'city': city,
    'country': country,
    'address': address,
    'profileImageUrl': profileImageUrl,
    'termsAccepted': termsAccepted,
    'emailVerified': emailVerified,
    'active': active,
  };

  String encode() => jsonEncode(toJson());

  factory AppUser.decode(String source) =>
      AppUser.fromJson(jsonDecode(source) as Map<String, dynamic>);

  AppUser copyWith({
    String? profileImageUrl,
    UserRole? role,
    String? phone,
    String? city,
    String? country,
    String? address,
  }) => AppUser(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    phone: phone ?? this.phone,
    role: role ?? this.role,
    city: city ?? this.city,
    country: country ?? this.country,
    address: address ?? this.address,
    profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    termsAccepted: termsAccepted,
    emailVerified: emailVerified,
    active: active,
  );
}
