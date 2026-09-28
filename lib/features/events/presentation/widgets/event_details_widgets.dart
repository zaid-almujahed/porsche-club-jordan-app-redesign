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
  });

  final int capacity;
  final int registeredCount;
  final DateTime startsAt;
  final int? weatherCelsius;

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
              Expanded(
                //Weather
                child: StatisticCard(
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
      showAppSnackBar(
        context,
        'Google Maps could not be opened.',
        type: AppFeedbackType.error,
      );
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
        onTap: canOpen ? () => _openInGoogleMaps(context) : null,
        child: _buildCard(hasCoordinates, canOpen),
      ),
    );
  }

  Widget _buildCard(bool hasCoordinates, bool canOpen) {
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.medium),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (hasCoordinates)
                    _OpenStreetMap(
                      latitude: latitude!,
                      longitude: longitude!,
                      location: location,
                    )
                  else
                    AppAssetImage(
                      path: mapImageUrl ?? '',
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AppRadii.medium),
                      ),
                      fallbackIcon: Icons.map_outlined,
                    ),
                  if (canOpen)
                    const Positioned(
                      left: 8,
                      bottom: 8,
                      child: _OpenInMapsPill(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tells the member the map opens in Google Maps.
class _OpenInMapsPill extends StatelessWidget {
  const _OpenInMapsPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 6, 11, 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.map_outlined, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            'Open in Google Maps',
            style: AppTextStyles.label.copyWith(
              color: Colors.white,
              fontSize: 10.5,
              letterSpacing: 0.3,
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
        Positioned(
          right: 8,
          bottom: 8,
          child: Material(
            color: Colors.black.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              onTap: () => launchUrl(
                Uri.parse('https://www.openstreetmap.org/copyright'),
                mode: LaunchMode.externalApplication,
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
              return AppAssetImage(
                path: widget.images[index],
                fit: BoxFit.cover,
                fallbackIcon: Icons.directions_car_outlined,
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

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sponsors.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final EventSponsor sponsor = sponsors[index];
          return Container(
            width: 118,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: AppAssetImage(
                    path: sponsor.logoUrl,
                    fit: BoxFit.contain,
                    fallbackIcon: Icons.image_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  sponsor.name,
                  maxLines: 1,
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
          );
        },
      ),
    );
  }
}
