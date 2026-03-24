import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/prayer_day.dart';

class MonthPrayerList extends StatelessWidget {
  const MonthPrayerList({super.key, required this.days});

  final List<PrayerDay> days;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 1),
      itemBuilder: (context, index) {
        final day = days[index];
        return _MonthDayRow(
          day: day,
          isFirst: index == 0,
          isLast: index == days.length - 1,
        );
      },
    );
  }
}

class _MonthDayRow extends StatelessWidget {
  const _MonthDayRow({
    required this.day,
    required this.isFirst,
    required this.isLast,
  });

  final PrayerDay day;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isToday = day.isToday;

    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(14) : Radius.zero,
      bottom: isLast ? const Radius.circular(14) : Radius.zero,
    );

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        color: isToday ? AppColors.primary.withValues(alpha: 0.06) : cs.surface,
        child: Column(
          children: [
            // Header tanggal
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  // Nomor tanggal
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primary
                          : cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.date.day}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isToday ? Colors.white : cs.onSurface,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Nama hari + tanggal Hijri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dayName(day.date.weekday),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isToday ? AppColors.primary : cs.onSurface,
                          ),
                        ),
                        Text(
                          day.hijriDateStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Hari ini',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Prayer times grid
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _TimeChip('Subuh', day.fajr, isToday: isToday),
                  _TimeChip('Dzuhur', day.dhuhr, isToday: isToday),
                  _TimeChip('Ashar', day.asr, isToday: isToday),
                  _TimeChip('Maghrib', day.maghrib, isToday: isToday),
                  _TimeChip('Isya', day.isha, isToday: isToday),
                ],
              ),
            ),

            if (!isLast)
              Divider(
                height: 1,
                color: cs.outline.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }

  String _dayName(int weekday) {
    const names = [
      'Senin', 'Selasa', 'Rabu', 'Kamis',
      'Jumat', 'Sabtu', 'Minggu',
    ];
    return names[weekday - 1];
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip(this.label, this.time, {required this.isToday});

  final String label;
  final String time;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: cs.onSurface.withValues(alpha: 0.45),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isToday ? AppColors.primary : cs.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
