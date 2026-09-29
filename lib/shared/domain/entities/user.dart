import 'vehicle.dart';

enum ApplicationStatus { notSubmitted, pending, approved, denied }

/// Backend `/member/membership` status → app state:
/// ACTIVE → active, APPROVED → inactive (not paid yet), EXPIRED → expired,
/// SUSPENDED / DEACTIVATED → suspended (signed out with a notice).
enum MembershipStatus { inactive, active, expired, suspended }

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.applicationStatus,
    required this.membershipStatus,
    this.memberId,
    this.avatarUrl,
    this.city,
    this.dateOfBirth,
    this.membershipValidUntil,
    this.vehicles = const <Vehicle>[],
  });

  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? memberId;
  final String? avatarUrl;
  final String? city;
  final DateTime? dateOfBirth;
  final ApplicationStatus applicationStatus;
  final MembershipStatus membershipStatus;
  final DateTime? membershipValidUntil;
  final List<Vehicle> vehicles;

  User copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? memberId,
    String? avatarUrl,
    String? city,
    DateTime? dateOfBirth,
    ApplicationStatus? applicationStatus,
    MembershipStatus? membershipStatus,
    DateTime? membershipValidUntil,
    List<Vehicle>? vehicles,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      memberId: memberId ?? this.memberId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      membershipValidUntil: membershipValidUntil ?? this.membershipValidUntil,
      vehicles: vehicles ?? this.vehicles,
    );
  }
}
