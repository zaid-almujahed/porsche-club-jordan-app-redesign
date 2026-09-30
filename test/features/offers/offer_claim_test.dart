import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/offers/domain/repositories/offers_repository.dart';
import 'package:pcj_v5/features/offers/presentation/controllers/offers_controller.dart';
import 'package:pcj_v5/features/offers/presentation/pages/offers_page.dart';
import 'package:pcj_v5/shared/domain/entities/offer.dart';

class _Offers implements OffersRepository {
  int claims = 0;

  @override
  Future<void> claimOffer(String offerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    claims++;
  }

  @override
  Future<List<Offer>> getOffers({
    String? category,
    bool forceRefresh = false,
  }) async => const <Offer>[
    Offer(
      id: '1',
      title: 'Nuqul Service',
      description: 'Ten percent off.',
      location: '',
      category: 'NUQUL',
      badgeLabel: '10% OFF',
      imageUrl: '',
      partnerName: 'Nuqul',
    ),
  ];
}

void main() {
  // Quick taps used to flip the card to "claiming" and back while the
  // previous switch was still animating, which threw "Duplicate keys".
  testWidgets('an offer is claimed once every five seconds, without errors', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final _Offers repository = _Offers();
    final OffersController controller = OffersController(
      repository: repository,
    );
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(home: PartnerOffersPage(controller: controller)),
    );
    await tester.pump(const Duration(seconds: 1));

    Future<void> spam() async {
      for (int i = 0; i < 30; i++) {
        await tester.tap(find.text('Nuqul Service'), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 60));
      }
      await tester.pump(const Duration(milliseconds: 500));
    }

    await spam();
    expect(repository.claims, 1);

    await tester.pump(const Duration(seconds: 5));
    await spam();
    expect(repository.claims, 2);

    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
}
