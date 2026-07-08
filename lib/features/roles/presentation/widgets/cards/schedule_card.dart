import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/widgets/custom_text.dart';
import '../../../../../widgets/loading/loading_widgets.dart';

class ScheduleCard extends StatelessWidget {
  final List<Map<String, dynamic>>? dailyCounts;
  const ScheduleCard({super.key, this.dailyCounts});

  @override
  Widget build(BuildContext context) {
    if (dailyCounts == null) {
      return const SizedBox(
        height: 100,
        child: Center(child: AppRingSpinner(size: 28)),
      );
    }

    final counts = dailyCounts!;
    final hasAny = counts.any((d) => (d['count'] as int) > 0);
    if (!hasAny) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No appointments scheduled',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: counts.length,
        separatorBuilder: (context, index) => const Gap(10),
        itemBuilder: (context, index) {
          final day = counts[index];
          final date = day['date'] as DateTime;
          final count = day['count'] as int;
          final isToday = day['isToday'] as bool;

          return Container(
            width: 65,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isToday ? const Color(0xff8FBAC7) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: isToday
                  ? null
                  : Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                if (isToday)
                  BoxShadow(
                    color: const Color(0xff8FBAC7).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                else
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      text: DateFormat('EEE').format(date).toUpperCase(),
                      size: 11,
                      color: isToday ? Colors.white : Colors.grey[500],
                      
                      weight: FontWeight.w600,
                    ),
                    if (isToday) ...[
                      const Gap(4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const CustomText(
                          text: 'Today',
                          size: 8,
                          color: Colors.white,
                          
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const Gap(4),
                CustomText(
                  text: DateFormat('d').format(date),
                  size: 20,
                  color: isToday ? Colors.white : Colors.black,
                  
                  weight: FontWeight.w700,
                ),
                const Gap(4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xff8FBAC7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: CustomText(
                    text: count.toString(),
                    size: 10,
                    color: isToday ? Colors.white : const Color(0xff8FBAC7),
                    
                    weight: FontWeight.w600,
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