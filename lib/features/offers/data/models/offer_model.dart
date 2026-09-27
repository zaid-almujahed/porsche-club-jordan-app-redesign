import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/shared/domain/entities/offer.dart';

export 'package:pcj_v5/shared/domain/entities/offer.dart';

class OfferModel extends Offer {
  const OfferModel({
    required super.id,
    required super.title,
    required super.description,
    required super.location,
    required super.category,
    required super.badgeLabel,
    required super.imageUrl,
    super.partnerName,
    super.discountRate,
    super.expiryDate,
    super.isClaimed,
    super.logoUrl,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    final String partnerName =
        firstString(json, const <String>['partner']) ?? '';
    final double? discount = firstDouble(
      json,
      const <String>['discount'],
    );

    return OfferModel(
      id: firstString(json, const <String>['offer_id']) ?? '',
      title: firstString(json, const <String>['title']) ?? '',
      description:
          firstString(json, const <String>['offer_details']) ?? '',
      location: '',
      category:
          partnerName.toLowerCase().contains('nuqul') ? 'NUQUL' : 'PARTNERS',
      badgeLabel: discount == null
          ? 'MEMBER OFFER'
          : '${discount.toStringAsFixed(0)}% OFF',
      imageUrl: '',
      partnerName: partnerName,
      discountRate: discount,
      expiryDate: firstDateTime(json, const <String>['expiry_date']),
      isClaimed: false,
      logoUrl: null,
    );
  }
}
