class EventGalleryItem {
  const EventGalleryItem({
    required this.id,
    required this.type,
    required this.fileUrl,
  });

  final String id;
  final String type;
  final String fileUrl;

  bool get isImage => type.trim().toLowerCase() == 'image';
}

class EventSponsor {
  const EventSponsor({
    required this.sponsorId,
    required this.tier,
    required this.name,
    required this.logoUrl,
  });

  final String sponsorId;
  final String tier;
  final String name;
  final String logoUrl;
}

class Event {
  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startsAt,
    required this.endsAt,
    required this.posterUrl,
    required this.capacity,
    required this.registeredCount,
    required this.guestLimit,
    required this.registrationFee,
    required this.guestFee,
    this.currency = 'JOD',
    this.sponsors = const <EventSponsor>[],
    this.gallery = const <EventGalleryItem>[],
    this.mapImageUrl,
    this.latitude,
    this.longitude,
    this.availableCount,
    this.weatherCelsius,
    this.precipitationProbability,
    this.windSpeedKmh,
    this.isPaid = false,
    this.isFeatured = false,
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startsAt;
  final DateTime endsAt;
  final String posterUrl;
  final int capacity;
  final int registeredCount;
  final int guestLimit;
  final double registrationFee;
  final double guestFee;
  final String currency;
  final List<EventSponsor> sponsors;
  final List<EventGalleryItem> gallery;
  final String? mapImageUrl;
  final double? latitude;
  final double? longitude;
  final int? availableCount;
  final int? weatherCelsius;

  /// Chance of rain at the event time, 0–100 (weather endpoint).
  final int? precipitationProbability;

  /// Wind speed at the event time in km/h (weather endpoint).
  final double? windSpeedKmh;
  final bool isPaid;
  final bool isFeatured;

  /// The cover first, then the gallery: the photo the event was opened from
  /// stays on screen while the details load.
  List<String> get photoUrls {
    final String cover = posterUrl.trim();
    final List<String> photos = <String>[
      if (cover.isNotEmpty) cover,
      ...galleryUrls.where((String url) => url.trim() != cover),
    ];
    return photos.isEmpty ? <String>[posterUrl] : photos;
  }

  List<String> get galleryUrls => gallery
      .where((EventGalleryItem item) => item.isImage)
      .map((EventGalleryItem item) => item.fileUrl)
      .where((String url) => url.trim().isNotEmpty)
      .toList(growable: false);

  /// A missing/zero capacity means the API did not publish a limit. It must
  /// not make every partially populated event look sold out.
  bool get isAtCapacity => availableCount != null
      ? availableCount! <= 0
      : capacity > 0 && registeredCount >= capacity;

  /// An explicit free-event flag is authoritative. When older responses omit
  /// it, the model infers [isPaid] from the published fee fields.

  bool hasStartedAt(DateTime moment) => startsAt.isBefore(moment);

  bool hasEndedAt(DateTime moment) => endsAt.isBefore(moment);

  bool isHappeningAt(DateTime moment) =>
      !startsAt.isAfter(moment) && !endsAt.isBefore(moment);

  Event copyWith({
    double? latitude,
    double? longitude,
    int? weatherCelsius,
    int? precipitationProbability,
    double? windSpeedKmh,
  }) {
    return Event(
      id: id,
      title: title,
      description: description,
      location: location,
      startsAt: startsAt,
      endsAt: endsAt,
      posterUrl: posterUrl,
      capacity: capacity,
      registeredCount: registeredCount,
      guestLimit: guestLimit,
      registrationFee: registrationFee,
      guestFee: guestFee,
      currency: currency,
      sponsors: sponsors,
      gallery: gallery,
      mapImageUrl: mapImageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      availableCount: availableCount,
      weatherCelsius: weatherCelsius ?? this.weatherCelsius,
      precipitationProbability:
          precipitationProbability ?? this.precipitationProbability,
      windSpeedKmh: windSpeedKmh ?? this.windSpeedKmh,
      isPaid: isPaid,
      isFeatured: isFeatured,
    );
  }
}
