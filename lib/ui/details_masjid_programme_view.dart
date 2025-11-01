import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ramadhan_companion_app/model/masjid_programme_model.dart';
import 'package:ramadhan_companion_app/provider/prayer_times_provider.dart';
import 'package:ramadhan_companion_app/widgets/app_colors.dart';
import 'package:ramadhan_companion_app/widgets/custom_button.dart';
import 'package:ramadhan_companion_app/widgets/custom_textfield.dart';
import 'package:url_launcher/url_launcher.dart';
import '../provider/masjid_programme_provider.dart';

class DetailsMasjidProgrammeView extends StatelessWidget {
  const DetailsMasjidProgrammeView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MasjidProgrammeProvider>();
    final prayerProvider = context.watch<PrayerTimesProvider>();

    final userCity = prayerProvider.city?.toLowerCase();
    final userCountry = prayerProvider.country?.toLowerCase();

    final allProgrammes = provider.filteredProgrammes;

    final programmes = allProgrammes.where((programme) {
      if (programme.isOnline) return true;
      final location = programme.location?.toLowerCase();
      if (location == null || (userCity == null && userCountry == null)) {
        return false;
      }

      final normalizedLocation = location.replaceAll(',', '').split(' ');
      final normalizedUser = ('$userCity $userCountry')
          .replaceAll(',', '')
          .split(' ');

      final hasMatch = normalizedUser.any(
        (word) =>
            word.isNotEmpty &&
            normalizedLocation.any((locWord) => locWord.contains(word)),
      );

      return hasMatch;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  CustomTextField(
                    label: 'Search Mosque',
                    onChanged: provider.filterByMasjid,
                  ),
                  const SizedBox(height: 10),
                  // CustomTextField(
                  //   label: 'Search Location',
                  //   onChanged: provider.filterByState,
                  // ),
                ],
              ),
            ),

            // 🔹 Programmes List
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : programmes.isEmpty
                  ? SizedBox(
                      height: 150,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Spacer(),
                            Image.asset(
                              'assets/icon/empty_data_icon.png',
                              height: 50,
                              width: 50,
                            ),
                            SizedBox(height: 5),
                            Text("No local programmes found in your state."),
                            Spacer(),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: programmes.length,
                      itemBuilder: (context, index) {
                        final programme = programmes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: _buildProgrammeCard(context, programme),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildAppBar(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Align(
            alignment: Alignment.centerLeft,
            child: const Icon(Icons.arrow_back),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Mosque Programmes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
      ],
    ),
  );
}

Widget _buildProgrammeCard(BuildContext context, MasjidProgramme programme) {
  final dateTimeFormatted = DateFormat(
    "d MMM yyyy, h:mm a",
  ).format(programme.dateTime);

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (programme.posterBytes != null)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.memory(
              programme.posterBytes!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "🕌 ${programme.isOnline ? "Online Programme" : programme.masjidName}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: programme.isOnline
                          ? Colors.green.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      border: Border.all(
                        color: programme.isOnline ? Colors.green : Colors.blue,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      programme.isOnline ? "Online" : "Offline",
                      style: TextStyle(
                        color: programme.isOnline ? Colors.green : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                "📝 ${programme.title}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),
              Text(
                "📅 $dateTimeFormatted",
                style: const TextStyle(fontSize: 12),
              ),

              const SizedBox(
                height: 12,
              ), // 👈 replaced Spacer with fixed spacing
              /// Location (if offline)
              if (!programme.isOnline && programme.location != null)
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        onTap: () async {
                          final query = Uri.encodeComponent(
                            programme.masjidName,
                          );
                          final url =
                              "https://www.google.com/maps/search/?api=1&query=$query";
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        text: 'Navigate me there',
                        backgroundColor: Colors.black,
                        textColor: Colors.white,
                      ),
                    ),

                    SizedBox(width: 10),
                    CircleAvatar(
                      backgroundColor: AppColors.lightGray.withOpacity(1),
                      child: IconButton(
                        icon: const Icon(Icons.alarm, color: Colors.black),
                        onPressed: () {
                          final event = Event(
                            title: programme.title,
                            description:
                                "Masjid programme at ${programme.masjidName}",
                            location: programme.isOnline
                                ? "Online"
                                : (programme.location ?? ""),
                            startDate: programme.dateTime,
                            endDate: programme.dateTime.add(
                              const Duration(hours: 2),
                            ),
                          );

                          Add2Calendar.addEvent2Cal(event);
                        },
                      ),
                    ),
                  ],
                ),

              /// Join link (if online)
              if (programme.isOnline && programme.joinLink != null)
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        onTap: () async {
                          final url = Uri.parse(programme.joinLink!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        text: 'Join Now',
                        backgroundColor: Colors.black,
                        textColor: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    CircleAvatar(
                      backgroundColor: AppColors.lightGray.withOpacity(1),
                      child: IconButton(
                        icon: const Icon(Icons.alarm, color: Colors.black),
                        onPressed: () {
                          final event = Event(
                            title: programme.title,
                            description:
                                "Masjid programme at ${programme.masjidName}",
                            location: programme.isOnline
                                ? "Online"
                                : (programme.location ?? ""),
                            startDate: programme.dateTime,
                            endDate: programme.dateTime.add(
                              const Duration(hours: 2),
                            ),
                          );

                          Add2Calendar.addEvent2Cal(event);
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
