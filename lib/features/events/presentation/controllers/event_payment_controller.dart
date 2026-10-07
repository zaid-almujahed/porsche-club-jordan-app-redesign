import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/presentation/controllers/cliq_transfer_controller.dart';

import '../../domain/repositories/events_repository.dart';

/// A paid event's registration, not sent yet: the payment page sends it
/// together with its CliQ payment.
class EventPaymentDetails {
  const EventPaymentDetails({
    required this.eventId,
    required this.eventTitle,
    required this.amount,
    this.currency = 'JOD',
    this.guestCount = 0,
    this.guestNames = const <String>[],
  });

  final String eventId;
  final String eventTitle;

  /// The event's price for the member and each guest.
  final double amount;
  final String currency;
  final int guestCount;
  final List<String> guestNames;
}

/// Paying for an event with CliQ. The RSVP is only sent once the payment
/// details are complete, and the payment right after it; a member never
/// holds an RSVP without a payment.
class EventPaymentController extends CliqTransferController {
  EventPaymentController({
    required EventsRepository repository,
    required super.imagePickerService,
    required this.payment,
  }) : _repository = repository;

  final EventsRepository _repository;
  final EventPaymentDetails payment;

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
  }) async {
    final String rsvpId = await _repository.registerForEvent(
      EventRegistrationRequest(
        eventId: payment.eventId,
        guestCount: payment.guestCount,
        guestNames: payment.guestNames,
      ),
    );
    try {
      if (rsvpId.isEmpty) {
        throw const AppException('The registration has no RSVP id.');
      }
      await _repository.payWithCliq(
        rsvpId: rsvpId,
        transactionNumber: transactionNumber,
        refundName: refundName,
        receipt: receipt,
      );
    } catch (_) {
      // An RSVP is never left without its payment.
      try {
        await _repository.cancelRegistration(payment.eventId);
      } catch (_) {
        throw const AppException(
          'Your payment could not be sent. Please contact support to '
          'complete your registration.',
        );
      }
      throw const AppException(
        'Your payment could not be sent, so you were not registered. '
        'Please try again.',
      );
    }
  }
}
