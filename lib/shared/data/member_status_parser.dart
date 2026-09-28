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
    if (value == true) return ApplicationStatus.approved;
    if (value == false) return ApplicationStatus.pending;
    final String status = value?.toString().toLowerCase().trim() ?? '';
    if (status.isEmpty) return ApplicationStatus.notSubmitted;
    if (status == 'active' ||
        status == 'inactive' ||
        status == 'expired' ||
        _isSuspended(status)) {
      return ApplicationStatus.approved;
    }
    if (status.contains('pending') || status.contains('review')) {
      return ApplicationStatus.pending;
    }
    if (status.contains('approve') || status.contains('accept')) {
      return ApplicationStatus.approved;
    }
    if (status.contains('denied') || status.contains('reject')) {
      return ApplicationStatus.denied;
    }
    // Any other non-empty membership status is denied access. Treating an
    // unknown backend status as a new application could expose registration
    // to an existing member and violates the status-routing contract.
    return ApplicationStatus.denied;
  }

  static MembershipStatus membership(Object? value) {
    if (value == true) return MembershipStatus.active;
    final String status = value?.toString().toLowerCase().trim() ?? '';
    if (_isSuspended(status)) return MembershipStatus.suspended;
    if (status.contains('inactive') || status == 'false') {
      return MembershipStatus.inactive;
    }
    if (status == 'true' || status == 'active') {
      return MembershipStatus.active;
    }
    if (status.contains('expired')) return MembershipStatus.expired;
    return MembershipStatus.inactive;
  }

  /// SUSPENDED and DEACTIVATED are handled identically.
  static bool _isSuspended(String status) =>
      status == 'suspended' || status == 'deactivated';
}
