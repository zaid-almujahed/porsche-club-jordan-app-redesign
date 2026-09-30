import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps each ticket's QR on the device. The backend issues it once (the
/// first view moves the RSVP to PARTIALLY_CHECKED_IN), so after that the
/// saved copy is the only one shown. Kept per member and across sign-outs.
abstract interface class TicketQrStore {
  Future<String?> read({required String memberId, required String eventId});

  Future<void> write({
    required String memberId,
    required String eventId,
    required String qrToken,
  });

  Future<void> delete({required String memberId, required String eventId});
}

class SecureTicketQrStore implements TicketQrStore {
  SecureTicketQrStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String _key(String memberId, String eventId) =>
      'pcj_ticket_qr_${memberId}_$eventId';

  @override
  Future<String?> read({
    required String memberId,
    required String eventId,
  }) async {
    try {
      return await _storage.read(key: _key(memberId, eventId));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write({
    required String memberId,
    required String eventId,
    required String qrToken,
  }) async {
    try {
      await _storage.write(key: _key(memberId, eventId), value: qrToken);
    } catch (_) {
      // The QR still shows now; it just is not kept for next time.
    }
  }

  @override
  Future<void> delete({
    required String memberId,
    required String eventId,
  }) async {
    try {
      await _storage.delete(key: _key(memberId, eventId));
    } catch (_) {
      // Nothing more to do.
    }
  }
}
