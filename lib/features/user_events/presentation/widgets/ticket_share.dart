import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';

/// Opens the share sheet (WhatsApp, Instagram, Messages, ...) with the
/// ticket as an image: the event title, date and location above its QR
/// code. [origin] is where the sheet points from on iPad.
Future<void> shareTicket({
  required Event event,
  required String qrToken,
  Rect? origin,
}) async {
  final String date = AppFormatters.dateAndTime(event.startsAt);
  final Uint8List image = await ticketShareImage(
    qrToken: qrToken,
    title: event.title,
    date: date,
    location: event.location,
  );
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[
        XFile.fromData(
          image,
          mimeType: 'image/png',
          name: 'pcj-ticket-${event.id}.png',
        ),
      ],
      text: <String>[
        event.title,
        date,
        event.location,
      ].where((String line) => line.trim().isNotEmpty).join('\n'),
      sharePositionOrigin: origin,
    ),
  );
}

/// A 1080 x 1350 PNG, centred like a ticket: the club name, the event's
/// title, date and location, then the QR on a white card (so it scans from
/// a screenshot) with "Scan at entrance" under it.
Future<Uint8List> ticketShareImage({
  required String qrToken,
  required String title,
  required String date,
  required String location,
}) async {
  const double width = 1080;
  const double height = 1350;
  const double textWidth = 880;
  const double qrSize = 520;
  const double cardPadding = 44;
  const double cardWidth = qrSize + cardPadding * 2;

  final List<_Line> lines = <_Line>[
    _Line(
      'PORSCHE CLUB JORDAN',
      const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: 8,
        color: AppColors.textMuted,
      ),
      gapAfter: 64,
    ),
    _Line(
      title,
      const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 64,
        fontWeight: FontWeight.w800,
        height: 1.12,
        color: Colors.white,
      ),
      maxLines: 2,
      gapAfter: 22,
    ),
    _Line(
      date,
      const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 34,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryBright,
      ),
      gapAfter: 8,
    ),
    if (location.trim().isNotEmpty)
      _Line(
        location,
        const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 32,
          color: AppColors.textSecondary,
        ),
      ),
  ];
  final List<TextPainter> painters = <TextPainter>[
    for (final _Line line in lines)
      TextPainter(
        text: TextSpan(text: line.text, style: line.style),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: line.maxLines,
        ellipsis: '…',
      )..layout(minWidth: textWidth, maxWidth: textWidth),
  ];
  final TextPainter caption = TextPainter(
    text: const TextSpan(
      text: 'SCAN AT ENTRANCE',
      style: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 6,
        color: Color(0xFF55555C),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  // Everything is centred as one block.
  double textHeight = 0;
  for (int i = 0; i < lines.length; i++) {
    textHeight += painters[i].height + lines[i].gapAfter;
  }
  const double textToCard = 64;
  final double cardHeight =
      cardPadding + qrSize + 28 + caption.height + cardPadding - 8;
  double y = (height - textHeight - textToCard - cardHeight) / 2;

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  const Rect page = Rect.fromLTWH(0, 0, width, height);
  canvas.drawRect(page, Paint()..color = const Color(0xFF0E0E10));
  // A faint red glow behind the heading.
  canvas.drawRect(
    page,
    Paint()
      ..shader = ui.Gradient.radial(
        const Offset(width / 2, 0),
        width * 0.8,
        <Color>[const Color(0x38D5001C), const Color(0x00D5001C)],
      ),
  );

  for (int i = 0; i < lines.length; i++) {
    painters[i].paint(canvas, Offset((width - textWidth) / 2, y));
    y += painters[i].height;
    if (i == 0) {
      // Red accent under the club name.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(width / 2, y + lines[0].gapAfter / 2),
            width: 72,
            height: 6,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = AppColors.primary,
      );
    }
    y += lines[i].gapAfter;
  }

  final Rect card = Rect.fromLTWH(
    (width - cardWidth) / 2,
    y + textToCard,
    cardWidth,
    cardHeight,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(card, const Radius.circular(44)),
    Paint()..color = Colors.white,
  );
  canvas.save();
  canvas.translate(card.left + cardPadding, card.top + cardPadding);
  QrPainter(
    data: qrToken,
    version: QrVersions.auto,
    gapless: true,
    eyeStyle: const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: Colors.black,
    ),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: Colors.black,
    ),
  ).paint(canvas, const Size.square(qrSize));
  canvas.restore();
  caption.paint(
    canvas,
    Offset((width - caption.width) / 2, card.top + cardPadding + qrSize + 28),
  );

  final ui.Image image = await recorder.endRecording().toImage(
    width.toInt(),
    height.toInt(),
  );
  final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return png!.buffer.asUint8List();
}

class _Line {
  const _Line(this.text, this.style, {this.maxLines = 1, this.gapAfter = 0});

  final String text;
  final TextStyle style;
  final int maxLines;
  final double gapAfter;
}
