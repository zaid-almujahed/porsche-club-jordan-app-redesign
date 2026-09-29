import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/core/state/safe_change_notifier.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';

import '../../domain/repositories/user_events_repository.dart';

class TicketController extends SafeChangeNotifier {
  TicketController({
    required UserEventsRepository repository,
    required this.bookingId,
    EventBooking? initialBooking,
  }) : _repository = repository,
       _booking = initialBooking == null
           ? const AsyncState<EventBooking>.initial()
           : AsyncState<EventBooking>.success(initialBooking),
       _ticket = _initialTicketState(initialBooking);

  final UserEventsRepository _repository;
  final String bookingId;
  AsyncState<EventBooking> _booking;
  AsyncState<EventTicket> _ticket;

  AsyncState<EventBooking> get booking => _booking;
  AsyncState<EventTicket> get ticket => _ticket;

  /// The QR shows while the RSVP is CONFIRMED and its attendance is "Not
  /// Checked In", whatever the time. [force] re-reads My Events (the ticket
  /// page does this every few seconds), so the QR is replaced by "already
  /// used" soon after the member is checked in.
  Future<void> load({bool force = false}) async {
    if (!force &&
        (_ticket.isLoading ||
            (_booking.hasData && _hasUsableTicket(_ticket.data)))) {
      return;
    }
    if (force || !_booking.hasData) {
      _booking = AsyncState<EventBooking>.loading(previousData: _booking.data);
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

    // Attendance and payment come from the My Events row.
    final EventTicket? included = _booking.data?.ticket;
    // Checked in: show that, and never ask for the QR again (the backend
    // does not generate it twice).
    if (included != null && !included.canDisplayQr) {
      _ticket = AsyncState<EventTicket>.success(included);
      notifyListeners();
      return;
    }
    // Still awaiting check-in: keep the QR already on screen.
    final EventTicket? shown = _ticket.data;
    if (shown != null &&
        shown.canDisplayQr &&
        shown.qrToken.trim().isNotEmpty) {
      notifyListeners();
      return;
    }

    _ticket = AsyncState<EventTicket>.loading(previousData: _ticket.data);
    notifyListeners();
    try {
      final EventTicket fetched = await _repository.getTicket(
        _booking.data!.event.id,
      );
      _ticket = AsyncState<EventTicket>.success(fetched);
    } catch (error, stackTrace) {
      _ticket = AsyncState<EventTicket>.failure(error, stackTrace);
    }
    notifyListeners();
  }

  static AsyncState<EventTicket> _initialTicketState(EventBooking? booking) {
    final EventTicket? ticket = booking?.ticket;
    return _hasUsableTicket(ticket)
        ? AsyncState<EventTicket>.success(ticket!)
        : const AsyncState<EventTicket>.initial();
  }

  static bool _hasUsableTicket(EventTicket? ticket) {
    return ticket != null &&
        (!ticket.canDisplayQr || ticket.qrToken.trim().isNotEmpty);
  }
}
