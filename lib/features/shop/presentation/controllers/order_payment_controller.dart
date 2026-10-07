import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';
import 'package:pcj_v5/shared/presentation/controllers/cliq_transfer_controller.dart';

import '../../domain/repositories/shop_repository.dart';

/// What an order's CliQ payment pays: the order's payment and its total.
class OrderPaymentDetails {
  const OrderPaymentDetails({
    required this.orderId,
    required this.paymentId,
    required this.amount,
    this.currency = 'JOD',
  });

  /// An order in My Orders still waiting for its payment.
  factory OrderPaymentDetails.fromOrder(Order order) {
    return OrderPaymentDetails(
      orderId: order.id,
      paymentId: order.paymentId ?? '',
      amount: order.total,
      currency: order.currency,
    );
  }

  final String orderId;
  final String paymentId;
  final double amount;
  final String currency;
}

/// Paying an order with CliQ.
class OrderPaymentController extends CliqTransferController {
  OrderPaymentController({
    required ShopRepository repository,
    required super.imagePickerService,
    required this.payment,
  }) : _repository = repository;

  final ShopRepository _repository;
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
    if (payment.paymentId.isEmpty) {
      throw const AppException(
        'This order cannot be paid from here. Please contact support.',
      );
    }
    return _repository.payOrderWithCliq(
      paymentId: payment.paymentId,
      transactionNumber: transactionNumber,
      refundName: refundName,
      receipt: receipt,
    );
  }
}
