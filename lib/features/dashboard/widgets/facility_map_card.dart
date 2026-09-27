import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../domain/models/dashboard/station_map_marker.dart';
import '../../../domain/models/dashboard/facility_map_zone.dart';
import '../../../domain/models/station_status.dart';

class FacilityMapCard extends StatelessWidget {
  final List<StationMapMarker> markers;
  final List<FacilityMapZone> zones;
  final ValueChanged<String>? onMarkerTap;

  const FacilityMapCard({
    super.key,
    required this.markers,
    required this.zones,
    this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live facility map',
              style: AppTypography.manropeBold.copyWith(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Map container
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC), // Very pale blue/gray
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: const Color(0xFFCBD5E1), // Light map border
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Semantics(
                  label:
                      'Facility floor plan with ${markers.length} station markers',
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          CustomPaint(
                            size: Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ),
                            painter: _FloorPlanPainter(zones: zones),
                          ),
                          // Optional: draw labels on top if we want them above markers, but the prompt says
                          // to keep labels structurally separate from marker placement. The painter draws the labels.
                          ...markers.map(
                            (marker) => _buildMarker(
                              marker,
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Legend
            Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 8,
              runSpacing: 4,
              children: [
                _LegendItem(color: AppColors.successGreen, label: 'Active'),
                _LegendItem(color: AppColors.criticalRed, label: 'Alert'),
                _LegendItem(color: AppColors.warningAmber, label: 'Low bait'),
                _LegendItem(color: AppColors.textTertiary, label: 'Offline'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarker(StationMapMarker marker, double width, double height) {
    Color color;
    switch (marker.status) {
      case StationStatus.online:
        color = AppColors.successGreen;
        break;
      case StationStatus.alert:
        color = AppColors.criticalRed;
        break;
      case StationStatus.lowBait:
        color = AppColors.warningAmber;
        break;
      case StationStatus.offline:
        color = AppColors.textTertiary;
        break;
    }

    final String shortId = marker.stationId.replaceAll(RegExp(r'[^0-9]'), '');

    return Positioned(
      left: marker.normalizedX * width - 12,
      top: marker.normalizedY * height - 12,
      child: Tooltip(
        message: marker.name,
        child: GestureDetector(
          onTap: onMarkerTap != null
              ? () => onMarkerTap!(marker.stationId)
              : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Semantics(
              label:
                  'Station ${marker.stationId}, status: ${marker.status.name}',
              button: true,
              child: Center(
                child: Text(
                  shortId,
                  style: AppTypography.manropeBold.copyWith(
                    fontSize: 8,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.manropeRegular.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FloorPlanPainter extends CustomPainter {
  final List<FacilityMapZone> zones;

  _FloorPlanPainter({required this.zones});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFFE2E8F0) // Light grid color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final zone in zones) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * zone.left,
          size.height * zone.top,
          size.width * zone.width,
          size.height * zone.height,
        ),
        paint,
      );

      _drawText(
        canvas,
        textPainter,
        zone.label,
        Offset(size.width * zone.labelX, size.height * zone.labelY),
      );
    }
  }

  void _drawText(
    Canvas canvas,
    TextPainter textPainter,
    String text,
    Offset center,
  ) {
    textPainter.text = TextSpan(
      text: text,
      style: const TextStyle(
        color: Color(0xFF94A3B8), // Muted map text
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _FloorPlanPainter oldDelegate) {
    return oldDelegate.zones != zones;
  }
}
