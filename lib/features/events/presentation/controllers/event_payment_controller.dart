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
    this.booking,
  });

  /// An RSVP still waiting for its payment (PENDING_PAYMENT); the amount is
  /// the event's price for the member and each guest.
  factory EventPaymentDetails.fromBooking(EventBooking booking) {
    return EventPaymentDetails(
      eventId: booking.event.id,
      eventTitle: booking.event.title,
      amount: booking.amountDue,
      currency: booking.event.currency,
      guestCount: booking.guestCount,
      guestNames: booking.guestNames,
      booking: booking,
    );
  }

  final String eventId;
  final String eventTitle;

  /// The event's price for the member and each guest.
  final double amount;
  final String currency;
  final int guestCount;
  final List<String> guestNames;

  /// Set for an RSVP already sent, waiting for its payment.
  final EventBooking? booking;
}

/// Paying for an event with CliQ. A new RSVP is only sent once the payment
/// details are complete, and the payment right after it; if the payment
/// fails, the RSVP is cancelled at once. An unpaid RSVP whose id is not
/// known is cancelled and sent again the same way.
class EventPaymentController extends CliqTransferController {
  EventPaymentController({
    required EventsRepository repository,
    required super.imagePickerService,
    required this.payment,
  }) : _repository = repository;

  final EventsRepository _repository;
  final EventPaymentDetails payment;

  /// An unpaid RSVP from My Events, whose rows have no `rsvp_id`: it is
  /// cancelled and sent again with the payment, as the reply gives the id.
  bool get renewsRegistration {
    final EventBooking? booking = payment.booking;
    return booking != null && (booking.rsvpId?.isEmpty ?? true);
  }

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
    final String? knownRsvpId = payment.booking?.rsvpId;
    if (knownRsvpId != null && knownRsvpId.isNotEmpty) {
      return _repository.payWithCliq(
        rsvpId: knownRsvpId,
        transactionNumber: transactionNumber,
        refundName: refundName,
        receipt: receipt,
      );
    }
    if (renewsRegistration) {
      await _repository.cancelRegistration(payment.eventId);
    }
    final String rsvpId;
    try {
      rsvpId = await _repository.registerForEvent(
        EventRegistrationRequest(
          eventId: payment.eventId,
          guestCount: payment.guestCount,
          guestNames: payment.guestNames,
        ),
      );
    } catch (_) {
      if (!renewsRegistration) rethrow;
      throw const AppException(
        'Your unpaid registration was cancelled, but registering again '
        'failed. Please register again from the event page.',
      );
    }
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
