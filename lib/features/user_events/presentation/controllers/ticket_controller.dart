import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/core/state/safe_change_notifier.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';

import '../../data/ticket_qr_store.dart';
import '../../domain/repositories/user_events_repository.dart';

class TicketController extends SafeChangeNotifier {
  TicketController({
    required UserEventsRepository repository,
    required TicketQrStore qrStore,
    required this.memberId,
    required this.bookingId,
    EventBooking? initialBooking,
  }) : _repository = repository,
       _qrStore = qrStore,
       _booking = initialBooking == null
           ? const AsyncState<EventBooking>.initial()
           : AsyncState<EventBooking>.success(initialBooking);

  final UserEventsRepository _repository;
  final TicketQrStore _qrStore;

  /// The signed-in member; saved QR codes are kept per member.
  final String memberId;
  final String bookingId;
  AsyncState<EventBooking> _booking;
  AsyncState<EventTicket> _ticket = const AsyncState<EventTicket>.initial();
  bool _isLoading = false;

  AsyncState<EventBooking> get booking => _booking;
  AsyncState<EventTicket> get ticket => _ticket;

  /// The ticket follows the RSVP's attendance on My Events:
  ///
  /// * "Not Checked In": the QR has never been issued. The first view asks
  ///   for it, saves it on the device before showing it, then re-reads My
  ///   Events to confirm the backend moved to PARTIALLY_CHECKED_IN.
  /// * PARTIALLY_CHECKED_IN: the saved QR shows. It is never requested
  ///   again.
  /// * CHECKED_IN: no QR; the page explains why.
  ///
  /// [force] re-reads My Events (the page does this every few seconds).
  Future<void> load({bool force = false}) async {
    if (_isLoading || (!force && _booking.hasData && _ticket.hasData)) return;
    _isLoading = true;
    bool isFirstView = false;
    try {
      if (force || !_booking.hasData) {
        _booking = AsyncState<EventBooking>.loading(
          previousData: _booking.data,
        );
        notifyListeners();
        try {
          _booking = AsyncState<EventBooking>.success(
            await _repository.getBooking(bookingId, forceRefresh: force),
          );
        } catch (error, stackTrace) {
          _booking = AsyncState<EventBooking>.failure(
            error,
            stackTrace,
            previousData: _booking.data,
          );
          notifyListeners();
          return;
        }
      }

      final EventBooking booking = _booking.data!;
      final String eventId = booking.event.id;
      final EventTicket row =
          booking.ticket ?? EventTicket(id: eventId, qrImageUrl: '');

      if (!row.canDisplayQr) {
        // Checked in: the saved QR is no longer needed.
        if (row.hasBeenUsed) {
          await _qrStore.delete(memberId: memberId, eventId: eventId);
        }
        _show(row);
        return;
      }

      final String? saved = await _qrStore.read(
        memberId: memberId,
        eventId: eventId,
      );
      if (saved != null && saved.isNotEmpty) {
        _show(_withQr(row, saved));
        return;
      }
      if (row.isPartiallyCheckedIn) {
        // Issued already, but not saved here (another device, or the app was
        // reinstalled): it is never requested again.
        _show(row);
        return;
      }

      isFirstView = true;
      _ticket = AsyncState<EventTicket>.loading(previousData: _ticket.data);
      notifyListeners();
      try {
        final EventTicket issued = await _repository.getTicket(eventId);
        if (issued.qrToken.isNotEmpty) {
          await _qrStore.write(
            memberId: memberId,
            eventId: eventId,
            qrToken: issued.qrToken,
          );
        }
        _show(_withQr(row, issued.qrToken));
      } catch (error, stackTrace) {
        isFirstView = false;
        _ticket = AsyncState<EventTicket>.failure(error, stackTrace);
        notifyListeners();
      }
    } finally {
      _isLoading = false;
    }
    // The backend marks the ticket PARTIALLY_CHECKED_IN on this first view;
    // re-read My Events to make sure the change went through.
    if (isFirstView) await load(force: true);
  }

  void _show(EventTicket ticket) {
    _ticket = AsyncState<EventTicket>.success(ticket);
    notifyListeners();
  }

  /// The row's attendance and payment, with the QR code.
  static EventTicket _withQr(EventTicket row, String qrToken) {
    return EventTicket(
      id: row.id,
      qrImageUrl: qrToken,
      attendanceStatus: row.attendanceStatus,
      isPaid: row.isPaid,
    );
  }
}
