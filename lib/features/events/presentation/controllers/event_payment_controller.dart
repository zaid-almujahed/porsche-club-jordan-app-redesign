import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';
import 'package:pcj_v5/shared/presentation/controllers/cliq_transfer_controller.dart';

import '../../domain/repositories/events_repository.dart';

/// What the payment page pays for: a paid event's registration, sent
/// together with its CliQ payment, or an RSVP that still waits for one.
class EventPaymentDetails {
  const EventPaymentDetails({
    required this.eventId,
    required this.eventTitle,
    required this.amount,
    this.currency = 'JOD',
    this.guestCount = 0,
    this.guestNames = const <String>[],
    this.rsvpId,
  });

  /// An RSVP still waiting for its payment (PENDING_PAYMENT); the amount is
  /// the event's price for the member and each guest.
  factory EventPaymentDetails.fromBooking(EventBooking booking) {
    return EventPaymentDetails(
      eventId: booking.event.id,
      eventTitle: booking.event.title,
      amount: booking.event.registrationFee * (1 + booking.guestCount),
      currency: booking.event.currency,
      guestCount: booking.guestCount,
      guestNames: booking.guestNames,
      rsvpId: booking.rsvpId ?? '',
    );
  }

  final String eventId;
  final String eventTitle;

  /// The event's price for the member and each guest.
  final double amount;
  final String currency;
  final int guestCount;
  final List<String> guestNames;

  /// Set for an RSVP already sent: only its payment is sent then. Empty
  /// when My Events did not give its id.
  final String? rsvpId;
}

/// Paying for an event with CliQ. A new RSVP is only sent once the payment
/// details are complete, and the payment right after it; if the payment
/// fails, the RSVP is cancelled at once.
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
    final String? sentRsvpId = payment.rsvpId;
    if (sentRsvpId != null) {
      if (sentRsvpId.isEmpty) {
        throw const AppException(
          'This registration cannot be paid from here. Please contact '
          'support.',
        );
      }
      return _repository.payWithCliq(
        rsvpId: sentRsvpId,
        transactionNumber: transactionNumber,
        refundName: refundName,
        receipt: receipt,
      );
    }
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
