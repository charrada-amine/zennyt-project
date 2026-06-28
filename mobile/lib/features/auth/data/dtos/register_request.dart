import '../../../../core/enums/user_role.dart';

/// Request body for `POST /auth/register`.
///
/// Note: `profileImageUrl` is intentionally absent — the backend `RegisterRequest`
/// does not accept it; the avatar is set afterwards via `PUT /users/me`.
class RegisterRequest {
  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.role,
    required this.termsAccepted,
    this.phoneNumber,
    this.city,
    this.country,
    this.address,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final UserRole role;
  final bool termsAccepted;
  final String? phoneNumber;
  final String? city;
  final String? country;
  final String? address;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'role': role.wireValue,
      'termsAccepted': termsAccepted,
    };
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      map['phoneNumber'] = phoneNumber;
    }
    if (city != null && city!.isNotEmpty) map['city'] = city;
    if (country != null && country!.isNotEmpty) map['country'] = country;
    if (address != null && address!.isNotEmpty) map['address'] = address;
    return map;
  }
}
