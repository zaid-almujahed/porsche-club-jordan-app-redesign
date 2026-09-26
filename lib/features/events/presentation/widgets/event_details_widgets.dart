import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pcj_v4/core/theme/app_theme.dart';
import 'package:pcj_v4/core/utils/app_formatters.dart';
import 'package:pcj_v4/shared/domain/entities/event.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pcj_v4/shared/widgets/app_widgets.dart';

//Contains event statistics; weather, cap, time, location

class EventStatistics extends StatelessWidget {
  const EventStatistics({
    super.key,
    required this.capacity,
    required this.registeredCount,
    required this.startsAt,
    this.weatherCelsius,
  });

  final int capacity;
  final int registeredCount;
  final DateTime startsAt;
  final int? weatherCelsius;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            //Weather
            child: StatisticCard(
              icon: Icons.wb_sunny_outlined,
              label: 'CURRENT',
              value: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: weatherCelsius == null ? '--°' : '$weatherCelsius°',
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
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatisticCard(
              icon: Icons.schedule_rounded,
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
          const SizedBox(width: 10),
          Expanded(
            child: StatisticCard(
              icon: Icons.groups_rounded,
              label: 'CAPACITY',
              value: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Text(
                  //   '$registeredCount ',
                  //   style: const TextStyle(
                  //     color: Color(0xFFE5E2E1),
                  //     fontSize: 28,
                  //     fontWeight: FontWeight.w600,
                  //   ),
                  // ),
                  Text(
                    '$capacity',
                    style: AppTextStyles.numeric.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBright,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total spots',
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
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

class StatisticCard extends StatelessWidget {
  const StatisticCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final Widget value;

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
              Icon(icon, size: 16, color: AppColors.primaryBright),
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

  @override
  Widget build(BuildContext context) {
    final bool hasCoordinates =
        latitude != null &&
        longitude != null &&
        (latitude != 0 || longitude != 0);
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
            options: MapOptions(initialCenter: point, initialZoom: 14),
            children: <Widget>[
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.porscheclubjordan.pcj_v4',
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
  const EventGallery({super.key, required this.images});

  final List<String> images;

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
    final double topInset = MediaQuery.paddingOf(context).top;

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

          //carousel indicators
          if (widget.images.length > 1)
            Positioned(
              top: topInset + 68,
              right: AppSpacing.lg,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x8C050507),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List<Widget>.generate(widget.images.length, (
                    int index,
                  ) {
                    final bool selected = index == _currentPage;
                    return AnimatedContainer(
                      duration: AppMotion.medium,
                      curve: AppMotion.curve,
                      width: selected ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.40),
                      ),
                    );
                  }),
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
                //const Spacer(),
                // Text(
                //   sponsor.tier.toUpperCase(),
                //   style: AppTextStyles.label.copyWith(
                //     color: AppColors.textFaint,
                //     fontSize: 10,
                //   ),
                // ),
              ],
            ),
          );
        },
      ),
    );
  }
}
