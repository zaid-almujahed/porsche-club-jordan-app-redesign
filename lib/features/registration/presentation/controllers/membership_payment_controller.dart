import 'package:flutter/material.dart';

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
  String _paymentMethod = 'meps_card';
  bool _isPaying = false;
  bool _hasAppliedReferralCode = false;
  Object? _paymentError;
  String? _paymentNotice;

  AsyncState<Membership> get state => _state;
  String get paymentMethod => _paymentMethod;
  bool get isPaying => _isPaying;
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
    _paymentNotice = null;
    notifyListeners();
  }

  void applyReferralCode() {
    final String code = referralCodeController.text.trim();
    if (code.isEmpty) {
      _hasAppliedReferralCode = false;
      notifyListeners();
      return;
    }

    // The published API has no code-validation endpoint. Keep Apply as a UI
    // confirmation and submit the code exactly once from pay().
    _hasAppliedReferralCode = true;
    _paymentError = null;
    _paymentNotice = null;
    notifyListeners();
  }

  void referralCodeChanged(String value) {
    if (!_hasAppliedReferralCode) return;
    _hasAppliedReferralCode = false;
    notifyListeners();
  }

  Future<Membership?> pay() async {
    if (_isPaying) return null;
    _isPaying = true;
    _paymentError = null;
    _paymentNotice = null;
    notifyListeners();
    try {
      final String code = referralCodeController.text.trim();
      final Membership membership = code.isEmpty
          ? await _repository.startMembershipPayment()
          : await _repository.activateWithCode(code);
      _state = AsyncState<Membership>.success(membership);
      if (membership.status != MembershipStatus.active) {
        _paymentNotice = code.isEmpty
            ? 'The payment request was started, but the backend has not '
                  'confirmed activation. Your access will remain locked until '
                  'payment confirmation is received.'
            : 'The code was submitted, but the backend has not confirmed '
                  'membership activation yet.';
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

  void reset() {
    referralCodeController.clear();
    _state = const AsyncState<Membership>.initial();
    _paymentMethod = 'meps_card';
    _isPaying = false;
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
