import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/prayer_day.dart';

class TodayPrayerCard extends StatelessWidget {
  const TodayPrayerCard({super.key, required this.today});

  final PrayerDay today;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nextPrayer = today.nextPrayer;

    final prayers = [
      (name: 'Imsak', time: today.imsak, prayer: PrayerName.imsak, showAlert: false),
      (name: 'Subuh', time: today.fajr, prayer: PrayerName.fajr, showAlert: true),
      (name: 'Terbit', time: today.sunrise, prayer: PrayerName.sunrise, showAlert: false),
      (name: 'Dzuhur', time: today.dhuhr, prayer: PrayerName.dhuhr, showAlert: true),
      (name: 'Ashar', time: today.asr, prayer: PrayerName.asr, showAlert: true),
      (name: 'Maghrib', time: today.maghrib, prayer: PrayerName.maghrib, showAlert: true),
      (name: 'Isya', time: today.isha, prayer: PrayerName.isha, showAlert: true),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: prayers.asMap().entries.map((entry) {
            final index = entry.key;
            final p = entry.value;

            final prayerTime = _toDateTime(p.time, today.date);
            final isPast = prayerTime.isBefore(DateTime.now());
            final isNext = nextPrayer?.name == p.name;

            return _PrayerRow(
              name: p.name,
              time: p.time,
              isPast: isPast,
              isNext: isNext,
              showAlert: p.showAlert,
              isLast: index == prayers.length - 1,
            );
          }).toList(),
        ),
      ),
    );
  }

  DateTime _toDateTime(String timeStr, DateTime base) {
    final parts = timeStr.split(':');
    return DateTime(base.year, base.month, base.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.name,
    required this.time,
    required this.isPast,
    required this.isNext,
    required this.showAlert,
    required this.isLast,
  });

  final String name;
  final String time;
  final bool isPast;
  final bool isNext;
  final bool showAlert;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isNext
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: cs.outline.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNext
                  ? AppColors.primary
                  : isPast
                      ? cs.outlineVariant
                      : cs.outline.withValues(alpha: 0.5),
            ),
          ),

          const SizedBox(width: 16),

          // Nama sholat
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                color: isNext
                    ? AppColors.primary
                    : isPast
                        ? cs.onSurface.withValues(alpha: 0.35)
                        : cs.onSurface,
                letterSpacing: -0.2,
              ),
            ),
          ),

          // "Berikutnya" tag
          if (isNext) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Berikutnya',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Waktu
          Text(
            time,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
              color: isNext
                  ? AppColors.primary
                  : isPast
                      ? cs.onSurface.withValues(alpha: 0.35)
                      : cs.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),

          // Bell icon
          if (showAlert) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.notifications_outlined,
              size: 16,
              color: isNext
                  ? AppColors.primary
                  : cs.onSurface.withValues(alpha: 0.25),
            ),
          ],
        ],
      ),
    );
  }
}
