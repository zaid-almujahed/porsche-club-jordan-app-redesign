import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/services/image_picker_service.dart';
import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';

import 'package:pcj_v5/features/profile/domain/repositories/membership_repository.dart';

class MembershipPaymentController extends ChangeNotifier {
  MembershipPaymentController({
    required MembershipRepository repository,
    ImagePickerService? imagePickerService,
  }) : _repository = repository,
       _imagePickerService = imagePickerService ?? ImagePickerService() {
    transactionController.addListener(notifyListeners);
    refundNameController.addListener(notifyListeners);
  }

  final MembershipRepository _repository;
  final ImagePickerService _imagePickerService;

  /// The gift / referral code being typed. Codes are single use, so it is
  /// cleared once accepted and whenever the code section closes; it never
  /// shows again on a later visit.
  final TextEditingController referralCodeController = TextEditingController();

  /// The transfer number on the bank's CliQ receipt.
  final TextEditingController transactionController = TextEditingController();

  /// The member's own CliQ alias, where a refund is sent.
  final TextEditingController refundNameController = TextEditingController();
  AsyncState<Membership> _state = const AsyncState<Membership>.initial();
  // Nothing is pre-selected; the member picks a payment method explicitly.
  String _paymentMethod = '';
  bool _isPaying = false;
  bool _isApplyingCode = false;
  Object? _paymentError;
  String? _paymentNotice;
  CliqPayment? _cliqPayment;
  CliqReceipt? _receipt;
  bool _isSendingReceipt = false;
  bool _isReplacingReceipt = false;

  AsyncState<Membership> get state => _state;
  String get paymentMethod => _paymentMethod;
  bool get isPaying => _isPaying;
  bool get isApplyingCode => _isApplyingCode;
  Object? get paymentError => _paymentError;
  String? get paymentNotice => _paymentNotice;

  /// The club's CliQ alias, once known, and the receipt sent from here.
  CliqPayment? get cliqPayment => _cliqPayment;

  /// A CliQ receipt is waiting for an admin: no other payment is taken and
  /// the member stays on its status until an admin decides.
  bool get hasPendingReceipt =>
      _cliqPayment?.receiptStatus == CliqReceiptStatus.pending;

  /// An admin turned the latest CliQ receipt down (FAILED).
  bool get hasRejectedReceipt =>
      _cliqPayment?.receiptStatus == CliqReceiptStatus.rejected;

  /// The latest receipt has a status to show: under review or rejected.
  bool get hasTransferWithClub => hasPendingReceipt || hasRejectedReceipt;

  /// Paying goes through the CliQ page: CliQ is chosen and offered, or a
  /// receipt is with the club.
  bool get paysWithCliq =>
      _cliqPayment != null && (_paymentMethod == 'cliq' || hasTransferWithClub);

  /// The CliQ page shows the receipt's status, unless the member is sending
  /// a new one after it was rejected.
  bool get showsReceiptReview =>
      hasPendingReceipt || (hasRejectedReceipt && !_isReplacingReceipt);

  /// The screenshot picked for the CliQ receipt, not sent yet.
  CliqReceipt? get receipt => _receipt;
  bool get isSendingReceipt => _isSendingReceipt;

  bool get canSubmitReceipt =>
      !_isSendingReceipt &&
      _receipt != null &&
      transactionController.text.trim().isNotEmpty &&
      refundNameController.text.trim().isNotEmpty;

  Future<void> load({bool force = false}) async {
    if (!force && (_state.isLoading || _state.hasData)) return;

    _state = AsyncState<Membership>.loading(previousData: _state.data);
    notifyListeners();

    final Future<CliqPayment?> cliqPayment = _loadCliqPayment();
    try {
      _state = AsyncState<Membership>.success(
        await _repository.getMembership(forceRefresh: force),
      );
    } catch (error, stackTrace) {
      _state = AsyncState<Membership>.failure(error, stackTrace);
    }
    _cliqPayment = await cliqPayment;
    notifyListeners();
  }

  // Without CliQ details, paying works as before. While the payment cannot
  // be read, the last known state stays.
  Future<CliqPayment?> _loadCliqPayment() async {
    try {
      return await _repository.getCliqPayment();
    } catch (_) {
      return _cliqPayment;
    }
  }

  Future<void> pickReceipt(PhotoSource source) async {
    final XFile? image = await _imagePickerService.pick(source);
    if (image == null) return;
    _receipt = CliqReceipt(
      bytes: await image.readAsBytes(),
      fileName: image.name,
    );
    _paymentError = null;
    notifyListeners();
  }

  void removeReceipt() {
    _receipt = null;
    notifyListeners();
  }

  /// "Send a New Payment" after a receipt was rejected.
  void replaceReceipt() {
    _isReplacingReceipt = true;
    notifyListeners();
  }

  /// Leaving the CliQ page drops a receipt that was not sent.
  void discardReceipt() {
    _receipt = null;
    _isReplacingReceipt = false;
    notifyListeners();
  }

  /// Sends the picked screenshot, the transfer number and the refund alias
  /// for an admin to check. True once sent.
  Future<bool> submitReceipt() async {
    final CliqReceipt? receipt = _receipt;
    final CliqPayment? payment = _cliqPayment;
    if (receipt == null || payment == null || !canSubmitReceipt) return false;
    _isSendingReceipt = true;
    _paymentError = null;
    notifyListeners();
    try {
      await _repository.submitCliqReceipt(
        receipt,
        transactionNumber: transactionController.text,
        refundName: refundNameController.text,
      );
      // The backend's word on it; until it can be read, the receipt just
      // sent is under review.
      final CliqPayment sent = CliqPayment(
        alias: payment.alias,
        receiptStatus: CliqReceiptStatus.pending,
        submittedAt: DateTime.now(),
      );
      try {
        _cliqPayment = await _repository.getCliqPayment() ?? sent;
      } catch (_) {
        _cliqPayment = sent;
      }
      _receipt = null;
      transactionController.clear();
      _isReplacingReceipt = false;
      return true;
    } catch (error) {
      _paymentError = error;
      return false;
    } finally {
      _isSendingReceipt = false;
      notifyListeners();
    }
  }

  void selectPaymentMethod(String value) {
    _paymentMethod = value;
    _paymentError = null;
    _paymentNotice = null;
    notifyListeners();
  }

  /// Submits the gift/referral code as soon as Apply is pressed (it used to
  /// wait for "Continue to Payment"). Returns the membership once the backend
  /// has accepted the code and the membership is active (for a renewal too),
  /// otherwise null with an error or notice set.
  Future<Membership?> applyReferralCode() async {
    final String code = referralCodeController.text.trim();
    if (code.isEmpty) {
      _paymentError = const AppException('Enter your gift or referral code.');
      notifyListeners();
      return null;
    }
    if (_isApplyingCode || _isPaying) return null;

    _isApplyingCode = true;
    _paymentError = null;
    _paymentNotice = null;
    notifyListeners();
    try {
      final Membership membership = await _repository.activateWithCode(code);
      _state = AsyncState<Membership>.success(membership);
      referralCodeController.clear();
      if (membership.status != MembershipStatus.active) {
        _paymentNotice =
            'The code was accepted, but the backend has not confirmed '
            'membership activation yet.';
        return null;
      }
      return membership;
    } catch (error) {
      _paymentError = error;
      return null;
    } finally {
      _isApplyingCode = false;
      notifyListeners();
    }
  }

  /// Returns the membership once payment (or a typed-but-unapplied code) is
  /// confirmed by the backend (it is active again); otherwise null with an
  /// error or notice set.
  Future<Membership?> pay() async {
    if (_isPaying || _isApplyingCode) return null;
    final String code = referralCodeController.text.trim();
    // A code that was typed but never applied is still honoured here.
    final bool useCode = code.isNotEmpty;
    if (!useCode && _paymentMethod.isEmpty) {
      _paymentError = const AppException(
        'Choose a payment method to continue.',
      );
      notifyListeners();
      return null;
    }

    _isPaying = true;
    _paymentError = null;
    _paymentNotice = null;
    notifyListeners();
    try {
      final Membership membership = useCode
          ? await _repository.activateWithCode(code)
          : await _repository.startMembershipPayment();
      _state = AsyncState<Membership>.success(membership);
      if (useCode) referralCodeController.clear();
      if (membership.status != MembershipStatus.active) {
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

  void reset() {
    referralCodeController.clear();
    transactionController.clear();
    refundNameController.clear();
    _state = const AsyncState<Membership>.initial();
    _paymentMethod = '';
    _isPaying = false;
    _isApplyingCode = false;
    _paymentError = null;
    _paymentNotice = null;
    _cliqPayment = null;
    _receipt = null;
    _isSendingReceipt = false;
    _isReplacingReceipt = false;
    notifyListeners();
  }

  @override
  void dispose() {
    referralCodeController.dispose();
    transactionController.dispose();
    refundNameController.dispose();
    super.dispose();
  }
}
