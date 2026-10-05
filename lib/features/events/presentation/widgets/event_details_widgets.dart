import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pcj_v5/shared/widgets/app_widgets.dart';

//Contains event statistics; weather, cap, time, location

class EventStatistics extends StatelessWidget {
  const EventStatistics({
    super.key,
    required this.capacity,
    required this.registeredCount,
    required this.startsAt,
    this.weatherCelsius,
    this.guestLimit = 0,
    this.precipitationProbability,
    this.windSpeedKmh,
    this.showWeather = true,
    this.forecastFrom,
    this.weatherUnavailable = false,
  });

  /// The weather was asked for and nothing came back: the card says so.
  final bool weatherUnavailable;

  /// Set while the event is beyond the forecast: the weather card says the
  /// forecast is on its way, and from when.
  final DateTime? forecastFrom;

  bool get _hasWeather =>
      weatherCelsius != null ||
      precipitationProbability != null ||
      windSpeedKmh != null;

  bool get _showsWeather => showWeather && (_hasWeather || weatherUnavailable);

  final int capacity;
  final int registeredCount;
  final DateTime startsAt;
  final int? weatherCelsius;

  /// False beyond the forecast window ([Event.hasForecastAt]); the tile also
  /// stays hidden while there is no weather to show.
  final bool showWeather;

  /// Guests each member may bring (`Max_guest_count`); 0 = members only.
  final int guestLimit;

  /// Chance of rain (%) and wind speed (km/h) from the weather endpoint.
  final int? precipitationProbability;
  final double? windSpeedKmh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Capacity leads: spots and the guest allowance decide registration.
        _CapacityCard(capacity: capacity, guestLimit: guestLimit),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_showsWeather || forecastFrom != null) ...<Widget>[
                Expanded(
                  //Weather
                  child: !_showsWeather
                      ? _WeatherNote(
                          title: 'Awaiting forecast',
                          detail:
                              'Available from ${AppFormatters.date(forecastFrom!)}',
                        )
                      : !_hasWeather
                      ? const _NoWeatherInformation()
                      : StatisticCard(
                          icon: Icons.wb_sunny_outlined,
                          iconColor: AppColors.warning,
                          label: 'WEATHER',
                          // Temperature with rain chance and wind beside it.
                          value: Row(
                            children: <Widget>[
                              Text.rich(
                                TextSpan(
                                  children: <InlineSpan>[
                                    TextSpan(
                                      text: weatherCelsius == null
                                          ? '--°'
                                          : '$weatherCelsius°',
                                      style: AppTextStyles.numeric.copyWith(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'C',
                                      style: AppTextStyles.numeric.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 1,
                                height: 30,
                                color: AppColors.cardBorder,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Semantics(
                                    label: 'Chance of rain',
                                    child: _WeatherDetail(
                                      icon: Icons.water_drop_outlined,
                                      text: precipitationProbability == null
                                          ? '--%'
                                          : '$precipitationProbability%',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Semantics(
                                    label: 'Wind speed',
                                    child: _WeatherDetail(
                                      icon: Icons.air_rounded,
                                      text: windSpeedKmh == null
                                          ? '-- km/h'
                                          : '${windSpeedKmh!.round()} km/h',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: StatisticCard(
                  icon: Icons.schedule_rounded,
                  iconColor: AppColors.accentSteel,
                  label: 'TIME',
                  value: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppFormatters.time(startsAt),
                        style: AppTextStyles.numeric.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppFormatters.date(startsAt),
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              // Capacity moved to its own full-width card above.
            ],
          ),
        ),
      ],
    );
  }
}

class _WeatherDetail extends StatelessWidget {
  const _WeatherDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 13, color: AppColors.accentSteel),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontFeatures: AppTextStyles.tabularFigures,
          ),
        ),
      ],
    );
  }
}

/// Total spots and the guest allowance side by side. (The API does not
/// report current attendees, so there is no spots-taken figure.)
class _CapacityCard extends StatelessWidget {
  const _CapacityCard({required this.capacity, required this.guestLimit});

  final int capacity;
  final int guestLimit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: AppDecorations.panel(radius: AppRadii.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.groups_rounded,
                size: 16,
                color: AppColors.primaryBright,
              ),
              const SizedBox(width: 6),
              Text(
                'CAPACITY',
                style: AppTextStyles.overline.copyWith(fontSize: 10.5),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          IntrinsicHeight(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _CapacityFigure(
                    value: capacity > 0 ? '$capacity' : '—',
                    label: capacity > 0 ? 'TOTAL SPOTS' : 'OPEN CAPACITY',
                    valueColor: AppColors.primaryBright,
                  ),
                ),
                const VerticalDivider(
                  width: AppSpacing.xl,
                  thickness: 1,
                  color: AppColors.cardBorder,
                ),
                Expanded(
                  child: _CapacityFigure(
                    value: guestLimit > 0 ? '+$guestLimit' : '0',
                    label: 'GUESTS PER MEMBER',
                    caption: guestLimit > 0 ? null : 'Members only',
                    icon: guestLimit > 0
                        ? Icons.person_add_alt_1_rounded
                        : Icons.person_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CapacityFigure extends StatelessWidget {
  const _CapacityFigure({
    required this.value,
    required this.label,
    this.caption,
    this.icon,
    this.valueColor = AppColors.textPrimary,
  });

  final String value;
  final String label;
  final String? caption;
  final IconData? icon;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppTextStyles.numeric.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            if (icon != null) ...<Widget>[
              const SizedBox(width: 6),
              Icon(icon, size: 18, color: AppColors.textMuted),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.overline.copyWith(fontSize: 9.5),
        ),
        if (caption != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(caption!, style: AppTextStyles.caption.copyWith(fontSize: 12)),
        ],
      ],
    );
  }
}

/// The weather card without weather: before the forecast reaches the
/// event, or when it could not be had.
class _WeatherNote extends StatelessWidget {
  const _WeatherNote({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return StatisticCard(
      icon: Icons.wb_sunny_outlined,
      iconColor: AppColors.warning,
      label: 'WEATHER',
      value: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              fontSize: 17,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(detail, style: AppTextStyles.caption.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

/// The weather was asked for and nothing came back.
class _NoWeatherInformation extends StatelessWidget {
  const _NoWeatherInformation();

  @override
  Widget build(BuildContext context) {
    return StatisticCard(
      icon: Icons.wb_sunny_outlined,
      iconColor: AppColors.warning,
      label: 'WEATHER',
      value: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.cloud_off_rounded,
            size: 26,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 4),
          Text(
            'No information available',
            style: AppTextStyles.caption.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// A past event's photos in a row; a photo (or "See all") opens them full
/// screen.
class PastEventPhotos extends StatelessWidget {
  const PastEventPhotos({super.key, required this.photos});

  final List<String> photos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'Photos',
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => showAppImageViewer(context, images: photos),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBright,
                textStyle: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text('See all ${photos.length}'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: photos.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (BuildContext context, int index) => Semantics(
              button: true,
              label: 'Photo ${index + 1} of ${photos.length}',
              child: GestureDetector(
                onTap: () => showAppImageViewer(
                  context,
                  images: photos,
                  initialIndex: index,
                ),
                child: SizedBox(
                  width: 170,
                  child: AppAssetImage(
                    path: photos[index],
                    borderRadius: BorderRadius.circular(AppRadii.medium),
                    fallbackIcon: Icons.photo_outlined,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// When and where a past event was.
class PastEventDetails extends StatelessWidget {
  const PastEventDetails({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final String place = event.location.trim();
    final List<(String, String)> rows = <(String, String)>[
      ('Date', AppFormatters.date(event.startsAt)),
      ('Time', AppFormatters.timeRange(event.startsAt, event.endsAt)),
      if (place.isNotEmpty) ('Place', place),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: AppDecorations.panel(radius: AppRadii.large),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1, color: AppColors.cardBorder),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(rows[i].$1, style: AppTextStyles.body),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.title.copyWith(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StatisticCard extends StatelessWidget {
  const StatisticCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.primaryBright,
  });

  final IconData icon;
  final String label;
  final Widget value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: AppDecorations.panel(radius: AppRadii.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.overline.copyWith(fontSize: 10.5),
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: value,
          ),
        ],
      ),
    );
  }
}

class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.location,
    this.mapImageUrl,
    this.latitude,
    this.longitude,
  });

  final String location;
  final String? mapImageUrl;
  final double? latitude;
  final double? longitude;

  bool get _hasCoordinates =>
      latitude != null &&
      longitude != null &&
      (latitude != 0 || longitude != 0);

  /// Opens the event in Google Maps (the app when installed, otherwise the
  /// browser): by coordinates when known, otherwise by searching the address.
  Future<void> _openInGoogleMaps(BuildContext context) async {
    final Uri uri =
        Uri.https('www.google.com', '/maps/search/', <String, String>{
          'api': '1',
          'query': _hasCoordinates ? '$latitude,$longitude' : location.trim(),
        });
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      showAppErrorPulse(context, 'Google Maps could not be opened.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCoordinates = _hasCoordinates;
    final bool canOpen = hasCoordinates || location.trim().isNotEmpty;
    return Semantics(
      button: canOpen,
      label: canOpen ? 'Open $location in Google Maps' : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canOpen ? () => _openInGoogleMaps(context) : null,
        child: _buildCard(hasCoordinates),
      ),
    );
  }

  Widget _buildCard(bool hasCoordinates) {
    return Container(
      height: 236,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: AppDecorations.panel(radius: AppRadii.large),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: AppColors.primaryBright,
                ),
                const SizedBox(width: 6),
                const Text('LOCATION', style: AppTextStyles.overline),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            // A still picture: taps go to the card, which opens Google Maps.
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.medium),
                child: hasCoordinates
                    ? _OpenStreetMap(
                        latitude: latitude!,
                        longitude: longitude!,
                        location: location,
                      )
                    : AppAssetImage(
                        path: mapImageUrl ?? '',
                        fit: BoxFit.cover,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppRadii.medium),
                        ),
                        fallbackIcon: Icons.map_outlined,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenStreetMap extends StatelessWidget {
  const _OpenStreetMap({
    required this.latitude,
    required this.longitude,
    required this.location,
  });

  final double latitude;
  final double longitude;
  final String location;

  @override
  Widget build(BuildContext context) {
    final LatLng point = LatLng(latitude, longitude);
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: FlutterMap(
            // A still preview: taps open Google Maps and page scrolling
            // is not captured by the map.
            options: MapOptions(
              initialCenter: point,
              initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.porscheclubjordan.pcj_v5',
                maxNativeZoom: 19,
              ),
              MarkerLayer(
                markers: <Marker>[
                  Marker(
                    point: point,
                    width: 56,
                    height: 56,
                    child: Tooltip(
                      message: location,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: Colors.white, width: 2.5),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Color(0x80D5001C),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.directions_car_filled_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // The map licence asks for this credit to stay visible.
        Positioned(
          right: 8,
          bottom: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(color: Colors.white, fontSize: 9.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class EventGallery extends StatefulWidget {
  const EventGallery({super.key, required this.images, this.onPageChanged});

  final List<String> images;

  /// Reports the visible photo; the page shows the dots in the event header
  /// (the bottom of the photo is covered by the title).
  final ValueChanged<int>? onPageChanged;

  @override
  State<EventGallery> createState() => _EventGallery();
}

class _EventGallery extends State<EventGallery> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant EventGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage < widget.images.length) return;
    _currentPage = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.hasClients) _controller.jumpToPage(0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 440,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            physics: const PageScrollPhysics(),
            onPageChanged: (int index) {
              setState(() => _currentPage = index);
              widget.onPageChanged?.call(index);
            },
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () => showAppImageViewer(
                  context,
                  images: widget.images,
                  initialIndex: index,
                ),
                child: AppAssetImage(
                  path: widget.images[index],
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.directions_car_outlined,
                ),
              );
            },
          ),
          // Top scrim keeps the floating controls legible; the bottom fade
          // melts the photo into the page.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0x99000000),
                    Color(0x00000000),
                    Color(0x000F0F11),
                    Color(0xCC0F0F11),
                    AppColors.canvas,
                  ],
                  stops: <double>[0, 0.22, 0.45, 0.78, 1],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the event was deleted or withdrawn, e.g. when an older
/// notification still points to it.
class EventUnavailable extends StatelessWidget {
  const EventUnavailable({super.key, required this.onBrowseEvents});

  final VoidCallback onBrowseEvents;

  @override
  Widget build(BuildContext context) {
    return AppFadeSlideIn(
      duration: AppMotion.medium,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.section,
          horizontal: AppSpacing.xl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.panel,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(
                    Icons.event_busy_rounded,
                    color: AppColors.textMuted,
                    size: 30,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'This event is no longer available',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(fontSize: 19),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'It may have been cancelled or removed by the club. Have a '
                  'look at what else is coming up.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 46,
                  child: FilledButton(
                    onPressed: onBrowseEvents,
                    style: AppButtonStyles.outline(),
                    child: const Text('Browse Events'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SponsorsList extends StatelessWidget {
  const SponsorsList({super.key, required this.sponsors});

  final List<EventSponsor> sponsors;

  @override
  Widget build(BuildContext context) {
    if (sponsors.isEmpty) {
      return const Center(
        child: Text('No sponsors listed', style: AppTextStyles.body),
      );
    }

    // Names wrap onto up to three lines; every tile grows to the tallest.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int index = 0; index < sponsors.length; index++) ...<Widget>[
              if (index > 0) const SizedBox(width: 10),
              Container(
                width: 118,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                ),
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: 56,
                      child: AppAssetImage(
                        path: sponsors[index].logoUrl,
                        fit: BoxFit.contain,
                        fallbackIcon: Icons.image_outlined,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      sponsors[index].name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
