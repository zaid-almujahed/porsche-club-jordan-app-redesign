import 'package:flutter/material.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';

import 'package:pcj_v5/features/profile/domain/repositories/membership_repository.dart';

class MembershipPaymentController extends ChangeNotifier {
  MembershipPaymentController({required MembershipRepository repository})
    : _repository = repository;

  final MembershipRepository _repository;
  final TextEditingController referralCodeController = TextEditingController();
  AsyncState<Membership> _state = const AsyncState<Membership>.initial();
  // Nothing is pre-selected; the member picks a payment method explicitly.
  String _paymentMethod = '';
  bool _isPaying = false;
  bool _isApplyingCode = false;
  bool _hasAppliedReferralCode = false;
  Object? _paymentError;
  String? _paymentNotice;

  AsyncState<Membership> get state => _state;
  String get paymentMethod => _paymentMethod;
  bool get isPaying => _isPaying;
  bool get isApplyingCode => _isApplyingCode;
  bool get hasAppliedReferralCode => _hasAppliedReferralCode;
  Object? get paymentError => _paymentError;
  String? get paymentNotice => _paymentNotice;

  Future<void> load({bool force = false}) async {
    if (!force && (_state.isLoading || _state.hasData)) return;

    _state = AsyncState<Membership>.loading(previousData: _state.data);
    notifyListeners();

    try {
      _state = AsyncState<Membership>.success(
        await _repository.getMembership(forceRefresh: force),
      );
    } catch (error, stackTrace) {
      _state = AsyncState<Membership>.failure(error, stackTrace);
    }
    notifyListeners();
  }

  void selectPaymentMethod(String value) {
    _paymentMethod = value;
    _paymentError = null;
    _paymentNotice = null;
    notifyListeners();
  }

  /// Submits the gift/referral code as soon as Apply is pressed (it used to
  /// wait for "Continue to Payment"). Returns the membership once the backend
  /// confirms activation, otherwise null with an error or notice set.
  Future<Membership?> applyReferralCode({bool isRenewal = false}) async {
    final String code = referralCodeController.text.trim();
    if (code.isEmpty) {
      _hasAppliedReferralCode = false;
      _paymentError = const AppException('Enter your gift or referral code.');
      notifyListeners();
      return null;
    }
    if (_isApplyingCode || _isPaying) return null;

    final DateTime? previousEnd = _state.data?.validUntil;
    _isApplyingCode = true;
    _paymentError = null;
    _paymentNotice = null;
    notifyListeners();
    try {
      final Membership membership = await _repository.activateWithCode(code);
      _state = AsyncState<Membership>.success(membership);
      _hasAppliedReferralCode = true;
      if (!_isConfirmed(membership, isRenewal, previousEnd)) {
        _paymentNotice =
            'The code was accepted, but the backend has not confirmed '
            'membership activation yet.';
        return null;
      }
      return membership;
    } catch (error) {
      _hasAppliedReferralCode = false;
      _paymentError = error;
      return null;
    } finally {
      _isApplyingCode = false;
      notifyListeners();
    }
  }

  void referralCodeChanged(String value) {
    if (!_hasAppliedReferralCode) return;
    _hasAppliedReferralCode = false;
    notifyListeners();
  }

  /// Returns the membership once payment (or a typed-but-unapplied code) is
  /// confirmed by the backend; otherwise null with an error or notice set.
  /// For [isRenewal] (an active member renewing early), confirmation means
  /// the end date moved forward.
  Future<Membership?> pay({bool isRenewal = false}) async {
    if (_isPaying || _isApplyingCode) return null;
    final String code = referralCodeController.text.trim();
    // A code that was typed but never applied is still honoured here.
    final bool useCode = code.isNotEmpty && !_hasAppliedReferralCode;
    if (!useCode && _paymentMethod.isEmpty) {
      _paymentError = const AppException(
        'Choose a payment method to continue.',
      );
      notifyListeners();
      return null;
    }

    final DateTime? previousEnd = _state.data?.validUntil;
    _isPaying = true;
    _paymentError = null;
    _paymentNotice = null;
    notifyListeners();
    try {
      final Membership membership = useCode
          ? await _repository.activateWithCode(code)
          : await _repository.startMembershipPayment();
      _state = AsyncState<Membership>.success(membership);
      if (!_isConfirmed(membership, isRenewal, previousEnd)) {
        _paymentNotice = useCode
            ? 'The code was submitted, but the backend has not confirmed '
                  'membership activation yet.'
            : 'The payment request was started, but the backend has not '
                  'confirmed it yet. Your membership will update once '
                  'payment confirmation is received.';
        return null;
      }
      return membership;
    } catch (error) {
      _paymentError = error;
      return null;
    } finally {
      _isPaying = false;
      notifyListeners();
    }
  }

  static bool _isConfirmed(
    Membership membership,
    bool isRenewal,
    DateTime? previousEnd,
  ) {
    if (membership.status != MembershipStatus.active) return false;
    if (!isRenewal) return true;
    final DateTime? end = membership.validUntil;
    return end != null && (previousEnd == null || end.isAfter(previousEnd));
  }

  void reset() {
    referralCodeController.clear();
    _state = const AsyncState<Membership>.initial();
    _paymentMethod = '';
    _isPaying = false;
    _isApplyingCode = false;
    _hasAppliedReferralCode = false;
    _paymentError = null;
    _paymentNotice = null;
    notifyListeners();
  }

  @override
  void dispose() {
    referralCodeController.dispose();
    super.dispose();
  }
}
