import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pcj_v5/core/services/image_picker_service.dart';
import 'package:pcj_v5/core/state/safe_change_notifier.dart';
import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';

/// Paying with CliQ: the member sends the amount from their bank app, then
/// gives the transfer number, their own alias for a refund and a screenshot
/// of the receipt. An admin approves it.
abstract class CliqTransferController extends SafeChangeNotifier {
  CliqTransferController({required ImagePickerService imagePickerService})
    : _imagePickerService = imagePickerService {
    transactionController.addListener(notifyListeners);
    refundNameController.addListener(notifyListeners);
  }

  final ImagePickerService _imagePickerService;

  /// The transfer number on the bank's receipt.
  final TextEditingController transactionController = TextEditingController();

  /// The member's own CliQ alias, where a refund is sent.
  final TextEditingController refundNameController = TextEditingController();

  String? _alias;
  CliqReceipt? _receipt;
  bool _isSubmitting = false;
  Object? _error;

  double get amount;
  String get currency;

  /// The club's CliQ alias, once known.
  String? get alias => _alias;
  CliqReceipt? get receipt => _receipt;
  bool get isSubmitting => _isSubmitting;
  Object? get error => _error;

  bool get canSubmit =>
      !_isSubmitting &&
      _receipt != null &&
      transactionController.text.trim().isNotEmpty &&
      refundNameController.text.trim().isNotEmpty;

  @protected
  Future<String?> loadAlias();

  /// Sends the payment to its endpoint.
  @protected
  Future<void> send({
    required String transactionNumber,
    required String refundName,
    required CliqReceipt receipt,
  });

  Future<void> load() async {
    _alias = await loadAlias();
    notifyListeners();
  }

  Future<void> pickReceipt(PhotoSource source) async {
    final XFile? image = await _imagePickerService.pick(source);
    if (image == null) return;
    _receipt = CliqReceipt(
      bytes: await image.readAsBytes(),
      fileName: image.name,
    );
    _error = null;
    notifyListeners();
  }

  void removeReceipt() {
    _receipt = null;
    notifyListeners();
  }

  /// Sends the transfer number, the refund alias and the receipt. True once
  /// sent.
  Future<bool> submit() async {
    final CliqReceipt? receipt = _receipt;
    if (!canSubmit || receipt == null) return false;
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await send(
        transactionNumber: transactionController.text.trim(),
        refundName: refundNameController.text.trim(),
        receipt: receipt,
      );
      return true;
    } catch (error) {
      _error = error;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    transactionController.dispose();
    refundNameController.dispose();
    super.dispose();
  }
}
