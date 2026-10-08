import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/presentation/controllers/cliq_transfer_controller.dart';

import '../../domain/repositories/shop_repository.dart';
import 'checkout_controller.dart';

/// What the payment page pays: a CliQ order not placed yet, placed together
/// with its payment, or an order whose payment is still PENDING.
class OrderPaymentDetails {
  const OrderPaymentDetails({
    required this.amount,
    this.currency = 'JOD',
    this.paymentId,
  });

  final double amount;
  final String currency;

  /// Set for an order already placed: only its payment is sent then.
  final String? paymentId;
}

/// Paying for the cart with CliQ. The order is only placed once the payment
/// details are complete, and the payment is sent right after it.
class OrderPaymentController extends CliqTransferController {
  OrderPaymentController({
    required ShopRepository repository,
    required CheckoutController checkout,
    required super.imagePickerService,
    required this.payment,
  }) : _repository = repository,
       _checkout = checkout;

  final ShopRepository _repository;
  final CheckoutController _checkout;
  final OrderPaymentDetails payment;

  @override
  double get amount => payment.amount;

  @override
  String get currency => payment.currency;

  @override
  Future<String?> loadAlias() => _repository.getCliqAlias();

  @override
  Future<void> send({
    required String transactionNumber,
    required String refundName,
    required CliqReceipt receipt,
  }) {
    final String? paymentId = payment.paymentId;
    if (paymentId != null) {
      return _repository.payOrderWithCliq(
        paymentId: paymentId,
        transactionNumber: transactionNumber,
        refundName: refundName,
        receipt: receipt,
      );
    }
    return _checkout.placeCliqOrder(
      transactionNumber: transactionNumber,
      refundName: refundName,
      receipt: receipt,
    );
  }
}
