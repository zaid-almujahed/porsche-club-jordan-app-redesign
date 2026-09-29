import 'dart:math' as math;

import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';

export 'package:pcj_v5/shared/domain/entities/event.dart';

class EventModel extends Event {
  const EventModel({
    required super.id,
    required super.title,
    required super.description,
    required super.location,
    required super.startsAt,
    required super.endsAt,
    required super.posterUrl,
    required super.capacity,
    required super.registeredCount,
    required super.guestLimit,
    required super.registrationFee,
    required super.guestFee,
    super.currency,
    super.sponsors,
    super.gallery,
    super.mapImageUrl,
    super.latitude,
    super.longitude,
    super.availableCount,
    super.weatherCelsius,
    super.precipitationProbability,
    super.windSpeedKmh,
    super.isPaid,
    super.isFeatured,
  });

  factory EventModel.fromSummaryJson(Map<String, dynamic> json) {
    return EventModel._fromJson(json, detailed: false, usesEventId: false);
  }

  factory EventModel.fromDetailsJson(
    Map<String, dynamic> json, {
    Event? fallbackEvent,
  }) {
    return EventModel._fromJson(
      json,
      detailed: true,
      usesEventId: false,
      fallbackEvent: fallbackEvent,
    );
  }

  factory EventModel.fromMemberEventJson(Map<String, dynamic> json) {
    return EventModel._fromJson(
      json,
      detailed: false,
      usesEventId: true,
    );
  }

  factory EventModel._fromJson(
    Map<String, dynamic> json, {
    required bool detailed,
    required bool usesEventId,
    Event? fallbackEvent,
  }) {
    // Shown exactly as scheduled: "14:30:00+02:00" is 2:30 PM, whatever the
    // phone's time zone.
    final DateTime startsAt =
        firstWallClockDateTime(json, const <String>['start_at']) ??
        fallbackEvent?.startsAt ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final int capacity =
        firstInt(json, const <String>['capacity']) ??
        fallbackEvent?.capacity ??
        0;
    // The guest allowance comes from `Max_guest_count` on
    // /member/events/{id}. Until the backend publishes it, no guests are
    // offered.
    final int? publishedGuestLimit = firstInt(json, const <String>[
      'Max_guest_count',
    ]);
    final int guestLimit = math.max(
      0,
      publishedGuestLimit ??
          // The details response is authoritative; summaries may reuse a
          // value already read from it.
          (detailed ? 0 : fallbackEvent?.guestLimit ?? 0),
    );

    return EventModel(
      id: firstString(
            json,
            <String>[usesEventId ? 'event_id' : 'id'],
          ) ??
          fallbackEvent?.id ??
          '',
      title:
          firstString(json, const <String>['title']) ??
          fallbackEvent?.title ??
          '',
      description:
          firstString(json, const <String>['description']) ??
          fallbackEvent?.description ??
          '',
      location:
          firstString(json, const <String>['location']) ??
          fallbackEvent?.location ??
          '',
      startsAt: startsAt,
      // The supplied event contracts do not contain an end time. Retain a
      // previously hydrated value when available; otherwise the only
      // documented timestamp is used as the event boundary.
      endsAt: fallbackEvent?.endsAt ?? startsAt,
      posterUrl: firstString(json, const <String>['cover_image']) ??
          fallbackEvent?.posterUrl ??
          '',
      capacity: capacity,
      registeredCount: fallbackEvent?.registeredCount ?? 0,
      guestLimit: guestLimit,
      registrationFee: fallbackEvent?.registrationFee ?? 0,
      guestFee: 0,
      currency: fallbackEvent?.currency ?? 'JOD',
      sponsors: detailed
          ? _sponsors(json['sponsors'])
          : fallbackEvent?.sponsors ?? const <EventSponsor>[],
      gallery: detailed
          ? _gallery(json['gallery'])
          : fallbackEvent?.gallery ?? const <EventGalleryItem>[],
      mapImageUrl: fallbackEvent?.mapImageUrl,
      latitude: firstDouble(json, const <String>['latitude']) ??
          fallbackEvent?.latitude,
      longitude: firstDouble(json, const <String>['longitude']) ??
          fallbackEvent?.longitude,
      availableCount: fallbackEvent?.availableCount,
      weatherCelsius: fallbackEvent?.weatherCelsius,
      precipitationProbability: fallbackEvent?.precipitationProbability,
      windSpeedKmh: fallbackEvent?.windSpeedKmh,
      isPaid: json['is_paid'] == true || (fallbackEvent?.isPaid ?? false),
      isFeatured: fallbackEvent?.isFeatured ?? false,
    );
  }

  static List<EventSponsor> _sponsors(Object? value) {
    if (value is! List) return const <EventSponsor>[];
    final List<EventSponsor> sponsors = value
        .whereType<Map>()
        .map<EventSponsor?>((Map item) {
          final Map<String, dynamic> json = Map<String, dynamic>.from(item);
          final String? sponsorId = firstString(
            json,
            const <String>['sponsor_id'],
          );
          final String? tier = firstString(json, const <String>['tier']);
          final String? name = firstString(
            json,
            const <String>['sponor_name'],
          );
          final String? logoUrl = firstString(
            json,
            const <String>['sponsor_logo'],
          );
          if (sponsorId == null ||
              tier == null ||
              name == null ||
              logoUrl == null) {
            return null;
          }
          return EventSponsor(
            sponsorId: sponsorId,
            tier: tier,
            name: name,
            logoUrl: logoUrl,
          );
        })
        .whereType<EventSponsor>()
        .toList();
    sponsors.sort(
      (EventSponsor left, EventSponsor right) =>
          _tierOrder(left.tier).compareTo(_tierOrder(right.tier)),
    );
    return List<EventSponsor>.unmodifiable(sponsors);
  }

  static int _tierOrder(String tier) {
    return switch (tier.trim().toLowerCase()) {
      'platinum' => 0,
      'gold' => 1,
      'silver' => 2,
      'bronze' => 3,
      _ => 4,
    };
  }

  static List<EventGalleryItem> _gallery(Object? value) {
    if (value is! List) return const <EventGalleryItem>[];
    return value
        .whereType<Map>()
        .map<EventGalleryItem?>((Map item) {
          final Map<String, dynamic> json = Map<String, dynamic>.from(item);
          final String? id = firstString(json, const <String>['id']);
          final String? type = firstString(json, const <String>['type']);
          final String? fileUrl = firstString(
            json,
            const <String>['file_url'],
          );
          if (id == null || type == null || fileUrl == null) return null;
          return EventGalleryItem(id: id, type: type, fileUrl: fileUrl);
        })
        .whereType<EventGalleryItem>()
        .toList(growable: false);
  }
}
