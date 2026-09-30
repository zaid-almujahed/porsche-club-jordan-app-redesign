import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import 'ticket_share.dart';

abstract final class VirtualTicketStyles {
  static const LinearGradient panelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1C1C20), Color(0xFF131316)],
  );

  static const BoxDecoration cardDecoration = BoxDecoration(
    gradient: panelGradient,
    border: Border.fromBorderSide(BorderSide(color: AppColors.cardBorder)),
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.large + 4)),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Color(0x59000000),
        blurRadius: 40,
        offset: Offset(0, 20),
        spreadRadius: -12,
      ),
    ],
  );

  static const TextStyle accessLabel = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textMuted,
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 1.6,
  );

  static const TextStyle eventTitle = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: Colors.white,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.6,
  );

  static const TextStyle date = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle scanLabel = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: 2.4,
  );

  static const TextStyle informationLabel = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 1.6,
  );

  static const TextStyle emphasizedInformationLabel = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 1.6,
  );

  static const TextStyle informationValue = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle guestValue = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
}

class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.booking,
    required this.ticket,
    required this.memberName,
  });

  final EventBooking booking;
  final EventTicket ticket;
  final String memberName;

  @override
  Widget build(BuildContext context) {
    if (ticket.hasBeenUsed) {
      return const TicketStatePanel(
        icon: Icons.verified_rounded,
        color: AppColors.success,
        title: 'YOU ARE CHECKED IN',
        message:
            'Your ticket was scanned at the event, so its QR code can no '
            'longer be shown. Enjoy the event!',
      );
    }
    if (!ticket.canDisplayQr) {
      return const TicketStatePanel(
        icon: Icons.qr_code_2_rounded,
        color: AppColors.warning,
        title: 'QR CODE UNAVAILABLE',
        message:
            'The QR code cannot be displayed because the server did not '
            'confirm that this ticket is awaiting check-in.',
      );
    }
    if (ticket.qrToken.trim().isEmpty) {
      return const TicketStatePanel(
        icon: Icons.phonelink_lock_rounded,
        color: AppColors.warning,
        title: 'QR CODE ALREADY ISSUED',
        message:
            'The QR code is issued once, the first time the ticket is opened, '
            'and is kept on that phone. For security it cannot be shown '
            'again here; please use the phone you first opened it on.',
      );
    }

    if (!ticket.isPaid) {
      return const TicketStatePanel(
        icon: Icons.lock_clock_outlined,
        color: AppColors.warning,
        title: 'PAYMENT PENDING',
        message:
            'The QR code will be available after the event payment is '
            'confirmed.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppFadeSlideIn(
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: VirtualTicketStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _TicketHeader(booking: booking),
                const _TicketPerforation(),
                _TicketQrSection(ticket: ticket),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppFadeSlideIn(
          delay: const Duration(milliseconds: 140),
          child: _TicketInformation(booking: booking, memberName: memberName),
        ),
        const SizedBox(height: AppSpacing.md),
        AppFadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: Builder(
            builder: (BuildContext buttonContext) => SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _share(buttonContext),
                style: AppButtonStyles.outline(radius: AppRadii.medium),
                icon: const Icon(Icons.ios_share_rounded, size: 20),
                label: const AppButtonLabel('Share Ticket'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _share(BuildContext buttonContext) async {
    final RenderBox? box = buttonContext.findRenderObject() as RenderBox?;
    try {
      await shareTicket(
        event: booking.event,
        qrToken: ticket.qrToken,
        origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (buttonContext.mounted) {
        showAppSnackBar(
          buttonContext,
          'The ticket could not be shared. Please try again.',
          type: AppFeedbackType.error,
        );
      }
    }
  }
}

/// Informational ticket state (used, unpaid, past or unavailable).
class TicketStatePanel extends StatelessWidget {
  const TicketStatePanel({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppFadeSlideIn(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        decoration: VirtualTicketStyles.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppScaleIn(
              begin: 0.8,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      color.withValues(alpha: 0.22),
                      color.withValues(alpha: 0.04),
                    ],
                  ),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: color, size: 34),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: VirtualTicketStyles.scanLabel,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({required this.booking});

  final EventBooking booking;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Event poster fades in from the right edge, as in the reference.
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 230,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (Rect bounds) => const LinearGradient(
                colors: <Color>[Color(0x00000000), Color(0xCC000000)],
                stops: <double>[0, 0.7],
              ).createShader(bounds),
              child: AppAssetImage(
                path: booking.event.posterUrl,
                fallbackIcon: Icons.directions_car_outlined,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const StatusBadge(
                  label: 'Confirmed Access',
                  color: AppColors.success,
                  icon: Icons.check_circle_rounded,
                ),
                const Spacer(),
                const Text('EVENT', style: VirtualTicketStyles.accessLabel),
                const SizedBox(height: 4),
                Text(
                  booking.event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: VirtualTicketStyles.eventTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      AppFormatters.date(booking.event.startsAt),
                      style: VirtualTicketStyles.date,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed tear line with half-circle notches cut into both card edges.
class _TicketPerforation extends StatelessWidget {
  const _TicketPerforation();

  static const double _notch = 26;

  @override
  Widget build(BuildContext context) {
    Widget notch() => Container(
      width: _notch,
      height: _notch,
      decoration: BoxDecoration(
        color: AppColors.canvas,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardBorder),
      ),
    );

    return SizedBox(
      height: _notch,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(left: -_notch / 2, top: 0, child: notch()),
          Positioned(right: -_notch / 2, top: 0, child: notch()),
          const Positioned.fill(
            left: _notch,
            right: _notch,
            child: CustomPaint(painter: _DashedLinePainter()),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1.2;
    const double dash = 7;
    const double gap = 5;
    final double y = size.height / 2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + dash).clamp(0, size.width), y),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}

class _TicketQrSection extends StatelessWidget {
  const _TicketQrSection({required this.ticket});

  final EventTicket ticket;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: AppScaleIn(
              begin: 0.9,
              duration: AppMotion.slow,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadii.large),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x26FFFFFF),
                        blurRadius: 30,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: ticket.qrToken.trim().isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.qr_code_2,
                            color: Colors.black,
                            size: 64,
                          ),
                        )
                      : QrImageView(
                          data: ticket.qrToken,
                          version: QrVersions.auto,
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            color: Colors.black,
                            eyeShape: QrEyeShape.square,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            color: Colors.black,
                            dataModuleShape: QrDataModuleShape.square,
                          ),
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                          errorStateBuilder:
                              (BuildContext context, Object? error) {
                                return const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: AppColors.danger,
                                    size: 44,
                                  ),
                                );
                              },
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(AppRadii.medium),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: const Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.primaryBright,
                      size: 24,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'SCAN AT ENTRANCE',
                      textAlign: TextAlign.center,
                      style: VirtualTicketStyles.scanLabel,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketInformation extends StatelessWidget {
  const _TicketInformation({required this.booking, required this.memberName});

  final EventBooking booking;
  final String memberName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: VirtualTicketStyles.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _InfoRow(
              icon: Icons.schedule_rounded,
              color: AppColors.accentSteel,
              child: _TicketValue(
                label: 'TIME',
                value: AppFormatters.timeRange(
                  booking.event.startsAt,
                  booking.event.endsAt,
                ),
                emphasizeLabel: true,
              ),
            ),
            const Divider(color: AppColors.cardBorder),
            _InfoRow(
              icon: Icons.location_on_rounded,
              child: _TicketValue(
                label: 'LOCATION',
                value: booking.event.location,
              ),
            ),
            const Divider(color: AppColors.cardBorder),
            _InfoRow(
              icon: Icons.badge_outlined,
              color: AppColors.accentGold,
              child: _TicketValue(
                label: 'MEMBER',
                value: memberName.trim().isEmpty ? 'Member' : memberName,
                largeValue: true,
                valueSpacing: 4,
              ),
            ),
            if (booking.guestCount > 0) ...<Widget>[
              const Divider(color: AppColors.cardBorder),
              _InfoRow(
                icon: Icons.group_outlined,
                color: AppColors.accentTeal,
                child: _TicketGuests(
                  count: booking.guestCount,
                  names: booking.guestNames,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The guests registered with the member: the count, then each name.
class _TicketGuests extends StatelessWidget {
  const _TicketGuests({required this.count, required this.names});

  final int count;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          count == 1 ? '1 GUEST' : '$count GUESTS',
          style: VirtualTicketStyles.informationLabel,
        ),
        const SizedBox(height: 3.5),
        if (names.isEmpty)
          Text(
            count == 1 ? '1 guest registered' : '$count guests registered',
            style: VirtualTicketStyles.informationValue,
          )
        else
          for (final String name in names)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(name, style: VirtualTicketStyles.informationValue),
            ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.child,
    this.color = AppColors.primaryBright,
  });

  final IconData icon;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIconBadge(icon: icon, color: color, size: 44, iconSize: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TicketValue extends StatelessWidget {
  const _TicketValue({
    required this.label,
    required this.value,
    this.emphasizeLabel = false,
    this.largeValue = false,
    this.valueSpacing = 3.5,
  });

  final String label;
  final String value;
  final bool emphasizeLabel;
  final bool largeValue;
  final double valueSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          label,
          style: emphasizeLabel
              ? VirtualTicketStyles.emphasizedInformationLabel
              : VirtualTicketStyles.informationLabel,
        ),
        SizedBox(height: valueSpacing),
        Text(
          value,
          style: largeValue
              ? VirtualTicketStyles.guestValue
              : VirtualTicketStyles.informationValue,
        ),
      ],
    );
  }
}
