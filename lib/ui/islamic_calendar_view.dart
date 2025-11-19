import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:ramadhan_companion_app/provider/islamic_calendar_provider.dart';

class IslamicCalendarView extends StatelessWidget {
  const IslamicCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IslamicCalendarProvider>(
      builder: (context, provider, child) {
        final days = provider.getDaysInMonth();
        final startWeekday = provider.firstWeekdayOfMonth();
        final leadingEmpty = startWeekday - 1;
        final todayKey = HijriCalendar.now().toFormat("dd/MM/yyyy");

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _buildAppBar(context),
                  const SizedBox(height: 20),
                  _buildYearAndNextMonth(provider),
                  const SizedBox(height: 10),

                  /// Weekday headers
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //   children: HijriCalendar.shortWeekdays
                  //       .map(
                  //         (day) => Expanded(
                  //           child: Center(
                  //             child: Text(
                  //               day,
                  //               style: const TextStyle(
                  //                 fontWeight: FontWeight.bold,
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //       )
                  //       .toList(),
                  // ),
                  const SizedBox(height: 10),

                  /// Calendar Grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 1,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                      itemCount: leadingEmpty + days.length,
                      itemBuilder: (context, index) {
                        if (index < leadingEmpty) {
                          return const SizedBox.shrink();
                        }

                        final day = days[index - leadingEmpty];
                        final isToday =
                            (day.toFormat("dd/MM/yyyy") == todayKey);

                        // Convert Hijri → Gregorian
                        final gregorian = day.hijriToGregorian(
                          day.hYear,
                          day.hMonth,
                          day.hDay,
                        );

                        // Check if this day is a special one
                        final isSpecial = provider.specialDays.any(
                          (s) => s.day == day.hDay && s.month == day.hMonth,
                        );

                        return Container(
                          decoration: BoxDecoration(
                            color: isToday
                                ? Colors.green.withOpacity(0.3)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                            border: isSpecial
                                ? Border.all(color: Colors.amber, width: 2)
                                : null,
                          ),
                          child: Stack(
                            children: [
                              /// Top-right Gregorian date
                              Positioned(
                                top: 4,
                                right: 6,
                                child: Text(
                                  gregorian.day.toString(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),

                              /// Center Hijri date
                              Center(
                                child: Text(
                                  "${day.hDay}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isToday
                                        ? Colors.green.shade800
                                        : Colors.black,
                                  ),
                                ),
                              ),

                              /// Optional indicator for special days
                              if (isSpecial)
                                const Positioned(
                                  bottom: 4,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildTitleText('Special Days'),
                  Expanded(
                    child: provider.specialDays.isEmpty
                        ? const Center(child: Text("No special days loaded"))
                        : ListView.builder(
                            itemCount: provider.specialDays
                                .where(
                                  (s) => s.month == provider.focusedDate.hMonth,
                                )
                                .length,
                            itemBuilder: (context, index) {
                              final filtered = provider.specialDays
                                  .where(
                                    (s) =>
                                        s.month == provider.focusedDate.hMonth,
                                  )
                                  .toList();
                              final special = filtered[index];

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: Image.asset(
                                    'assets/icon/glitter_icon.png',
                                    height: 30,
                                    width: 30,
                                  ),
                                  title: Text(special.name),
                                  subtitle: Text(
                                    "Hijri Day: ${special.day}  •  Gregorian: ${HijriCalendar().hijriToGregorian(provider.focusedDate.hYear, special.month, special.day).day}/${HijriCalendar().hijriToGregorian(provider.focusedDate.hYear, special.month, special.day).month}",
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _buildAppBar(BuildContext context) {
  return Row(
    children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back),
      ),
      const SizedBox(width: 10),
      const Text(
        "Islamic Calendar",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
      ),
    ],
  );
}

Widget _buildYearAndNextMonth(IslamicCalendarProvider provider) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        provider.monthYearLabel,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: provider.prevMonth,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: provider.nextMonth,
          ),
        ],
      ),
    ],
  );
}

Widget _buildTitleText(String name) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Text(
      name,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
    ),
  );
}
