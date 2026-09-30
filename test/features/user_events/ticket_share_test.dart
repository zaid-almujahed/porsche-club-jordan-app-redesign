import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/user_events/presentation/widgets/ticket_share.dart';

void main() {
  testWidgets('the shared ticket is a PNG image', (WidgetTester tester) async {
    final Uint8List? image = await tester.runAsync(
      () => ticketShareImage(
        qrToken: 'signed-ticket-token',
        title: 'Dead Sea Drive',
        date: '24 Oct, 2026 · 08:30 AM',
        location: 'Dead Sea',
      ),
    );

    // The PNG signature.
    expect(image!.take(4), <int>[0x89, 0x50, 0x4E, 0x47]);
  });
}
