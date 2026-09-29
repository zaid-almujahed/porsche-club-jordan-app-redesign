import 'package:pcj_v5/shared/domain/entities/user.dart';

/// Turns the backend's membership status (`status` on `/member/membership`)
/// into the app's two status fields. The only place these rules live; both
/// the signed-in user and the membership page use it.
///
/// | Backend value            | Application | Membership |
/// |--------------------------|-------------|------------|
/// | (missing)                | notSubmitted| inactive   |
/// | PENDING                  | pending     | inactive   |
/// | REJECTED                 | denied      | inactive   |
/// | APPROVED                 | approved    | inactive   |
/// | ACTIVE                   | approved    | active     |
/// | EXPIRED                  | approved    | expired    |
/// | SUSPENDED / DEACTIVATED  | approved    | suspended  |
/// | anything else            | denied      | inactive   |
abstract final class MemberStatusParser {
  static ApplicationStatus application(Object? value) {
    // Older profile fields report approval as true / false.
    if (value == true) return ApplicationStatus.approved;
    if (value == false) return ApplicationStatus.pending;
    return switch (_normalized(value)) {
      '' => ApplicationStatus.notSubmitted,
      'PENDING' => ApplicationStatus.pending,
      'REJECTED' => ApplicationStatus.denied,
      'APPROVED' ||
      'ACTIVE' ||
      'EXPIRED' ||
      'SUSPENDED' ||
      'DEACTIVATED' => ApplicationStatus.approved,
      // An unknown status never unlocks the app or reopens registration.
      _ => ApplicationStatus.denied,
    };
  }

  static MembershipStatus membership(Object? value) {
    if (value == true) return MembershipStatus.active;
    return switch (_normalized(value)) {
      'ACTIVE' => MembershipStatus.active,
      'EXPIRED' => MembershipStatus.expired,
      // SUSPENDED and DEACTIVATED are handled identically.
      'SUSPENDED' || 'DEACTIVATED' => MembershipStatus.suspended,
      _ => MembershipStatus.inactive,
    };
  }

  static String _normalized(Object? value) =>
      value?.toString().trim().toUpperCase() ?? '';
}
