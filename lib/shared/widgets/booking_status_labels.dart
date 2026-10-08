import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';

/// A state as a chip shows it: its words and colour.
typedef StatusLabel = ({String text, Color color});

/// How a booking's RSVP and its CliQ payment read, on My Events and the
/// event's page. Green is done, amber needs the member (to pay, or to pay
/// again after a FAILED payment), blue waits for the club, red was turned
/// down and grey is over.
extension BookingStatusLabels on EventBooking {
  /// The RSVP. A confirmed one reads its check-in state.
  StatusLabel get rsvpLabel {
    final String attendance =
        ticket?.attendanceStatus.replaceAll('_', ' ').trim().toUpperCase() ??
        '';
    return switch (status) {
      // A cancelled RSVP whose payment came back reads REFUNDED; its
      // payment chip is not shown.
      EventBookingStatus.canceled when paymentStatus == 'REFUNDED' => (
        text: 'REFUNDED',
        color: AppColors.success,
      ),
      EventBookingStatus.canceled => (
        text: 'CANCELLED',
        color: AppColors.textMuted,
      ),
      EventBookingStatus.rejected => (
        text: 'REJECTED',
        color: AppColors.danger,
      ),
      EventBookingStatus.pendingRefund => (
        text: 'REFUND PENDING',
        color: AppColors.accentSteel,
      ),
      EventBookingStatus.refunded => (
        text: 'REFUNDED',
        color: AppColors.success,
      ),
      _ when isRemovedByPayment => (
        text: 'REMOVED',
        color: AppColors.textMuted,
      ),
      EventBookingStatus.confirmed => (
        text: attendance.isEmpty ? 'CONFIRMED' : attendance,
        color: AppColors.success,
      ),
      EventBookingStatus.pendingPayment => (
        text: 'PENDING',
        color: AppColors.warning,
      ),
      EventBookingStatus.waitingAdminApproval => (
        text: 'AWAITING APPROVAL',
        color: AppColors.accentSteel,
      ),
    };
  }

  /// The CliQ payment of a paid event. Null for a free event, and once the
  /// payment is COMPLETED.
  StatusLabel? get paymentLabel {
    if (!event.isPaid) return null;
    final String? payment = paymentStatus;
    // A cancelled RSVP only shows a payment still in play: one to send, or
    // a refund pending or turned down.
    if (status == EventBookingStatus.canceled &&
        !const <String>{
          'PENDING',
          'PENDING_REFUND',
          'REFUND_PENDING',
          'REJECT_REFUNDED',
        }.contains(payment)) {
      return null;
    }
    if (payment != null) return paymentStatusLabel(payment);
    return switch (status) {
      EventBookingStatus.pendingPayment => (
        text: 'NOT SENT',
        color: AppColors.warning,
      ),
      EventBookingStatus.waitingAdminApproval => (
        text: 'UNDER REVIEW',
        color: AppColors.accentSteel,
      ),
      _ => null,
    };
  }
}

/// A CliQ payment's `payment_status` as a chip reads it, for an RSVP or an
/// order. Null when empty, and once it is COMPLETED: the chip is hidden then.
StatusLabel? paymentStatusLabel(String status) {
  return switch (status.trim().toUpperCase()) {
    '' || 'COMPLETED' => null,
    'PENDING' => (text: 'PENDING', color: AppColors.warning),
    'WAITING_ADMIN_APPROVAL' => (
      text: 'UNDER REVIEW',
      color: AppColors.accentSteel,
    ),
    'REJECTED' => (text: 'REJECTED', color: AppColors.danger),
    'FAILED' => (text: 'FAILED', color: AppColors.warning),
    'CANCELLED' ||
    'CANCELED' => (text: 'CANCELLED', color: AppColors.textMuted),
    'PENDING_REFUND' ||
    'REFUND_PENDING' => (text: 'REFUND PENDING', color: AppColors.accentSteel),
    'REJECT_REFUNDED' => (text: 'REFUND REJECTED', color: AppColors.danger),
    'REFUNDED' => (text: 'REFUNDED', color: AppColors.success),
    final String other => (
      text: other.replaceAll('_', ' '),
      color: AppColors.textMuted,
    ),
  };
}
