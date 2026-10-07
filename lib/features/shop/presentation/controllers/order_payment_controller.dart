import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/presentation/controllers/cliq_transfer_controller.dart';

import '../../domain/repositories/shop_repository.dart';
import 'checkout_controller.dart';

/// A CliQ order, not placed yet: the payment page places it together with
/// its payment.
class OrderPaymentDetails {
  const OrderPaymentDetails({required this.amount, this.currency = 'JOD'});

  final double amount;
  final String currency;
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
    return _checkout.placeCliqOrder(
      transactionNumber: transactionNumber,
      refundName: refundName,
      receipt: receipt,
    );
  }
}
