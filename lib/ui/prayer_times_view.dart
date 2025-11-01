import 'dart:ui';
import 'package:add_2_calendar/add_2_calendar.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:ramadhan_companion_app/helper/distance_calculation.dart';
import 'package:ramadhan_companion_app/helper/local_notifications.dart';
import 'package:ramadhan_companion_app/main.dart';
import 'package:ramadhan_companion_app/model/masjid_programme_model.dart';
import 'package:ramadhan_companion_app/provider/bookmark_provider.dart';
import 'package:ramadhan_companion_app/provider/carousel_provider.dart';
import 'package:ramadhan_companion_app/provider/location_input_provider.dart';
import 'package:ramadhan_companion_app/provider/masjid_programme_provider.dart';
import 'package:ramadhan_companion_app/provider/notifications_provider.dart';
import 'package:ramadhan_companion_app/provider/prayer_times_provider.dart';
import 'package:ramadhan_companion_app/provider/quran_provider.dart';
import 'package:ramadhan_companion_app/ui/details_bookmark_view.dart';
import 'package:ramadhan_companion_app/ui/details_masjid_programme_view.dart';
import 'package:ramadhan_companion_app/ui/details_verse_view.dart';
import 'package:ramadhan_companion_app/ui/hadith_books_view.dart';
import 'package:ramadhan_companion_app/ui/hadith_view.dart';
import 'package:ramadhan_companion_app/ui/islamic_calendar_view.dart';
import 'package:ramadhan_companion_app/ui/masjid_nearby_view.dart';
import 'package:ramadhan_companion_app/ui/notifications_view.dart';
import 'package:ramadhan_companion_app/ui/qibla_finder_view.dart';
import 'package:ramadhan_companion_app/ui/quran_detail_view.dart';
import 'package:ramadhan_companion_app/ui/quran_page_view.dart';
import 'package:ramadhan_companion_app/ui/quran_view.dart';
import 'package:ramadhan_companion_app/ui/sadaqah_view.dart';
import 'package:ramadhan_companion_app/ui/settings_view.dart';
import 'package:ramadhan_companion_app/widgets/app_colors.dart';
import 'package:ramadhan_companion_app/widgets/custom_button.dart';
import 'package:ramadhan_companion_app/widgets/custom_pill_snackbar.dart';
import 'package:ramadhan_companion_app/widgets/custom_textfield.dart';
import 'package:ramadhan_companion_app/widgets/shimmer_loading.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:convert';
import 'dart:math';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class PrayerTimesView extends StatelessWidget {
  const PrayerTimesView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerTimesProvider>();
    final masjidProgrammeProvider = context.watch<MasjidProgrammeProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!provider.shouldAskLocation) provider.initialize();
      updatePrayerWidget(provider);
      // schedulePrayerNotifications(provider);
      // if (!masjidProgrammeProvider.isLoading &&
      //     !masjidProgrammeProvider.allProgrammes.isNotEmpty) {
      //   masjidProgrammeProvider.loadProgrammes();
      // }
    });

    Future<void> refreshData() async {
      final provider = context.read<PrayerTimesProvider>();

      if (provider.city != null && provider.country != null) {
        await provider.fetchPrayerTimes(provider.city!, provider.country!);
        await updatePrayerWidget(provider);
        await masjidProgrammeProvider.loadProgrammes();
      }

      // await provider.refreshDailyContent();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle = isDarkMode
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        body: SafeArea(
          child: Consumer2<PrayerTimesProvider, CarouselProvider>(
            builder: (context, provider, carouselProvider, _) {
              if (provider.shouldAskLocation) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showLocationBottomSheet(context, provider);
                  provider.setLocationAsked();
                });
              }

              return RefreshIndicator(
                backgroundColor: Colors.white,
                color: AppColors.violet.withOpacity(1),
                onRefresh: refreshData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _HeaderDelegate(
                        minExtent: 50,
                        maxExtent: 90,
                        builder: (context, shrinkOffset, overlapsContent) {
                          final progress = (shrinkOffset / (90 - 40)).clamp(
                            0.0,
                            1.0,
                          );
                          return Container(
                            color: AppColors.lightGray.withOpacity(1),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 12 - (progress * 40),
                                  left: 1,
                                  right: 1,
                                  child: Opacity(
                                    opacity: 1 - progress,
                                    child: _buildWelcomeText(context, provider),
                                  ),
                                ),
                                Positioned(
                                  left: 1,
                                  right: 1,
                                  bottom: 8,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - progress)),
                                    child: _buildHijriAndGregorianDate(
                                      provider,
                                      context,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          _buildIconsGrid(context, provider),
                          _buildBookmark(context),
                          _buildSadaqahReminder(context),
                          const SizedBox(height: 20),
                          _buildCountdown(provider),
                          const SizedBox(height: 20),
                          _buildPrayerTimesSection(provider),
                          const SizedBox(height: 20),
                          _buildMasjidProgramme(context),
                          const SizedBox(height: 10),
                          _dailyVerseCarousel(
                            provider,
                            carouselProvider,
                            context,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

Widget _buildWelcomeText(BuildContext context, PrayerTimesProvider provider) {
  final user = FirebaseAuth.instance.currentUser;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Assalamualaikum,"),
            Text(
              user?.displayName ?? "User",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Spacer(),
        Consumer<NotificationsProvider>(
          builder: (context, notificationsProvider, _) {
            final unreadCount = notificationsProvider.notifications
                .where((n) => !(n['read'] ?? false))
                .length;

            return Stack(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationsView()),
                    );
                  },
                  child: const Icon(Icons.notifications_outlined, size: 25),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsView()),
            );
          },
          child: const Icon(Icons.settings_outlined, size: 25),
        ),
      ],
    ),
  );
}

Widget _buildHijriAndGregorianDate(
  PrayerTimesProvider provider,
  BuildContext context,
) {
  if (provider.isHijriDateLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerLoadingWidget(width: 120, height: 24, isCircle: false),
          SizedBox(height: 8),
          ShimmerLoadingWidget(width: 220, height: 18, isCircle: false),
        ],
      ),
    );
  }
  return provider.activeHijriDateModel != null
      ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: () => _showPrayerTimesDate(context, provider),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${provider.activeHijriDateModel!.hijriDay} "
                        "${provider.activeHijriDateModel!.hijriMonth} "
                        "${provider.activeHijriDateModel!.hijriYear}",
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${provider.activeHijriDateModel!.gregorianDay}, "
                        "${provider.activeHijriDateModel!.gregorianDayDate} "
                        "${provider.activeHijriDateModel!.gregorianMonth} "
                        "${provider.activeHijriDateModel!.gregorianYear}",
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: _buildLocationText(provider, context)),
            ],
          ),
        )
      : const SizedBox.shrink();
}

Widget _buildLocationText(PrayerTimesProvider provider, BuildContext context) {
  if (provider.city == null || provider.country == null) {
    return const SizedBox.shrink();
  }

  return InkWell(
    onTap: () => _showLocationBottomSheet(context, provider),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text("📍"),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            "${provider.city}, ${provider.country}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );
}

Widget _buildCountdown(PrayerTimesProvider provider) {
  if ((provider.times == null) && !provider.isPrayerTimesLoading) {
    return const SizedBox.shrink();
  }
  if (provider.isPrayerTimesLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerLoadingWidget(width: 120, height: 24, isCircle: false),
          SizedBox(height: 8),
          ShimmerLoadingWidget(width: 220, height: 18, isCircle: false),
        ],
      ),
    );
  }

  if (provider.countdownText.isNotEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.countdownText,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const TextSpan(text: "Countdown to the next prayer: "),
                  TextSpan(
                    text: provider.nextPrayerText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  return const SizedBox.shrink();
}

Widget _buildPrayerTimesSection(PrayerTimesProvider provider) {
  if ((provider.times == null) && !provider.isPrayerTimesLoading) {
    return const SizedBox.shrink();
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Column(
      children: [
        _buildPrayerRowWithHighlight("Fajr", provider.times?.fajr, provider),
        _buildPrayerRowWithHighlight(
          "Sunrise",
          provider.times?.sunrise,
          provider,
        ),
        _buildPrayerRowWithHighlight("Dhuhr", provider.times?.dhuhr, provider),
        _buildPrayerRowWithHighlight("Asr", provider.times?.asr, provider),
        _buildPrayerRowWithHighlight(
          "Maghrib",
          provider.times?.maghrib,
          provider,
        ),
        _buildPrayerRowWithHighlight("Isha", provider.times?.isha, provider),
      ],
    ),
  );
}

Widget _buildPrayerRowWithHighlight(
  String prayer,
  String? time,
  PrayerTimesProvider provider,
) {
  bool isNext = provider.nextPrayerText.toLowerCase() == prayer.toLowerCase();

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 3),
    decoration: BoxDecoration(
      color: isNext ? AppColors.lightViolet.withOpacity(0.9) : null,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8),
      child: _buildPrayerTimesRow(
        prayer,
        time,
        provider.isPrayerTimesLoading,
        isNext: isNext,
      ),
    ),
  );
}

Widget _buildMasjidProgramme(BuildContext context) {
  final provider = context.watch<PrayerTimesProvider>();
  final city = provider.city;
  final country = provider.country;

  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTitleText("Mosque Programmes Near You"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: CircleAvatar(
              backgroundColor: AppColors.betterGray.withOpacity(0.3),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailsMasjidProgrammeView(),
                    ),
                  );
                },
                child: Icon(
                  Icons.arrow_forward,
                  color: AppColors.violet.withOpacity(1),
                ),
              ),
            ),
          ),
        ],
      ),
      Consumer<MasjidProgrammeProvider>(
        builder: (context, programmeProvider, _) {
          if (programmeProvider.isLoading) {
            return _buildShimmerMasjidProgramme();
          }

          if (programmeProvider.allProgrammes.isEmpty) {
            return SizedBox(
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
            );
          }

          final programmes = programmeProvider.allProgrammes.where((programme) {
            if (programme.isOnline) return true;
            final location = programme.location?.toLowerCase();
            if (location == null || (city == null && country == null)) {
              return false;
            }

            final normalizedLocation = location.replaceAll(',', '').split(' ');
            final normalizedUser = ('$city $country')
                .replaceAll(',', '')
                .toLowerCase()
                .split(' ');

            final hasMatch = normalizedUser.any(
              (word) =>
                  word.isNotEmpty &&
                  normalizedLocation.any((locWord) => locWord.contains(word)),
            );
            return hasMatch;
          }).toList();

          if (programmes.isEmpty) {
            return SizedBox(
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
            );
          }

          return SizedBox(
            height: 380,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: programmes.length,
              itemBuilder: (context, index) {
                final programme = programmes[index];
                return Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.only(
                    left: index == 0 ? 12 : 8,
                    right: index == programmes.length - 1 ? 20 : 10,
                    top: 10,
                    bottom: 20,
                  ),
                  child: _buildProgrammeCard(context, programme),
                );
              },
            ),
          );
        },
      ),
    ],
  );
}

Widget _buildShimmerMasjidProgramme() {
  return SizedBox(
    height: 250,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(10),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          width: 250,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerLoadingWidget(height: 50, width: 50),
                SizedBox(height: 8),
                ShimmerLoadingWidget(height: 20, width: 70),
                SizedBox(height: 8),
                ShimmerLoadingWidget(height: 20, width: 90),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildProgrammeCard(
  BuildContext context,
  MasjidProgramme programme, {
  bool isSuperAdmin = false,
}) {
  final dateTimeFormatted = DateFormat(
    "d MMM yyyy, h:mm a",
  ).format(programme.dateTime);

  return Container(
    decoration: BoxDecoration(
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

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (isSuperAdmin && programme.status == 'expired')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Expired",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    Text(
                      "🕌 ${programme.isOnline ? "Online Programme" : programme.masjidName}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
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
                          color: programme.isOnline
                              ? Colors.green
                              : Colors.blue,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        programme.isOnline ? "Online" : "Offline",
                        style: TextStyle(
                          color: programme.isOnline
                              ? Colors.green
                              : Colors.blue,
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

                if (programme.isOnline == false)
                  Text("📍 ${programme.location}"),

                const SizedBox(height: 4),
                Text(
                  "📅  $dateTimeFormatted",
                  style: const TextStyle(fontSize: 12),
                ),

                Spacer(),

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
                          icon: const Icon(
                            Icons.share_outlined,
                            color: Colors.black,
                          ),
                          onPressed: () async {
                            final dateFormatted = DateFormat(
                              "EEEE, d MMM yyyy • h:mm a",
                            ).format(programme.dateTime);

                            final message =
                                '''
📣 *${programme.title}*

🕌 Hosted by: ${programme.masjidName}
📅 Date & Time: $dateFormatted
${programme.isOnline ? "🌐 Join Online" : "📍 Location: ${programme.location ?? "At the Masjid"}"}

You’re invited to join this blessed Masjid programme!

Download our app to explore more upcoming events and stay connected with your Masjid:
👉 Ummah: Muslim Community
📲 Get it on Google Play or App Store

#MasjidProgramme #IslamicEvent #JoinTheBlessing
''';

                            await Share.share(message);
                          },
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
                          icon: const Icon(
                            Icons.share_outlined,
                            color: Colors.black,
                          ),
                          onPressed: () async {
                            final dateFormatted = DateFormat(
                              "EEEE, d MMM yyyy • h:mm a",
                            ).format(programme.dateTime);

                            final message =
                                '''
📣 *${programme.title}*

🕌 Hosted by: ${programme.masjidName}
📅 Date & Time: $dateFormatted
${programme.isOnline ? "🌐 Join Online from ${programme.joinLink}" : "📍 Location: ${programme.location ?? "At the Masjid"}"}

You’re invited to join this blessed Masjid programme!

Download our app to explore more upcoming events and stay connected with your Masjid:
👉 Ummah: Muslim Community
📲 Get it on Google Play or App Store

#MasjidProgramme #IslamicEvent #JoinTheBlessing
''';

                            await Share.share(message);
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      CircleAvatar(
                        backgroundColor: AppColors.lightGray.withOpacity(1),
                        child: IconButton(
                          icon: const Icon(
                            Icons.share_outlined,
                            color: Colors.black,
                          ),
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
        ),
      ],
    ),
  );
}

Widget _dailyVerseCarousel(
  PrayerTimesProvider provider,
  CarouselProvider carouselProvider,
  BuildContext context,
) {
  return Column(
    children: [
      _buildTitleText("Daily Verse"),
      SizedBox(
        height: 250,
        child: PageView(
          controller: carouselProvider.pageController,
          onPageChanged: (index) {
            carouselProvider.onPageChanged(index);
          },
          children: [
            _buildDailyQuranVerse(provider, context),
            _buildHadithVerse(provider, context),
          ],
        ),
      ),
      const SizedBox(height: 8),
      SmoothPageIndicator(
        controller: carouselProvider.pageController,
        count: 2,
        effect: WormEffect(
          dotHeight: 13,
          dotWidth: 13,
          activeDotColor: AppColors.lightViolet.withOpacity(1),
        ),
      ),
    ],
  );
}

Widget _buildDailyQuranVerse(
  PrayerTimesProvider provider,
  BuildContext context,
) {
  return Padding(
    padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 20),
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VerseDetailView(type: "quran", verse: provider.quranDaily!),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.30),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: provider.isQuranVerseLoading
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerLoadingWidget(
                      width: 120,
                      height: 24,
                      isCircle: false,
                    ),
                    SizedBox(height: 20),
                    ShimmerLoadingWidget(
                      width: 220,
                      height: 18,
                      isCircle: false,
                    ),
                    SizedBox(height: 8),
                    ShimmerLoadingWidget(
                      width: 100,
                      height: 16,
                      isCircle: false,
                    ),
                  ],
                )
              : provider.quranDaily != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      provider.quranDaily!.arabic,
                      style: const TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 2.5,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    Text(
                      provider.quranDaily!.english,
                      style: const TextStyle(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          provider.quranDaily!.surahName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 2),
                        Text(": ${provider.quranDaily!.ayahNo}"),
                      ],
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ),
    ),
  );
}

Widget _buildHadithVerse(PrayerTimesProvider provider, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(left: 10.0, right: 10, top: 10, bottom: 20),
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VerseDetailView(type: "hadith", verse: provider.hadithDaily!),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.30),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: provider.hadithDaily == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerLoadingWidget(
                      width: 120,
                      height: 24,
                      isCircle: false,
                    ),
                    SizedBox(height: 20),
                    ShimmerLoadingWidget(
                      width: 220,
                      height: 18,
                      isCircle: false,
                    ),
                    SizedBox(height: 8),
                    ShimmerLoadingWidget(
                      width: 100,
                      height: 16,
                      isCircle: false,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.hadithDaily!.hadithArabic,
                      style: const TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 2.5,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.hadithDaily!.hadithEnglish,
                      style: const TextStyle(fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          provider.hadithDaily!.bookSlug,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 2),
                        Text(": ${provider.hadithDaily!.volume}"),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}

Widget _buildTitleText(String name) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12.0),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        name,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    ),
  );
}

Widget _buildTitleTextBottomSheet(String name) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        name,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
      ),
    ),
  );
}

// Widget _buildErrorText(PrayerTimesProvider provider) {
//   return provider.error != null
//       ? Center(
//           child: Text(
//             provider.error!,
//             style: const TextStyle(
//               color: Colors.red,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         )
//       : const SizedBox.shrink();
// }

Widget _buildPrayerTimesRow(
  String prayerName,
  String? prayerTime,
  bool isLoading, {
  bool isNext = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          prayerName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isNext ? Colors.white : null,
          ),
        ),
        isLoading
            ? const ShimmerLoadingWidget(width: 60, height: 16, isCircle: false)
            : Text(
                prayerTime ?? "--:--",
                style: TextStyle(
                  fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                  color: isNext ? Colors.white : null,
                ),
              ),
      ],
    ),
  );
}

Widget _buildInsertText() {
  return Text(
    "Please insert your city and country to determine prayer times.",
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
  );
}

Widget _buildIconsGrid(BuildContext context, PrayerTimesProvider provider) {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 20,
          children: [
            _buildQuran(context),
            _buildQiblaFinder(context, provider),
            _buildLocateMasjidNearby(context, provider),
            _buildSedekah(context),
            _buildHadith(context),
            _buildIslamicCalendar(context, provider),
          ],
        ),
      ),
      // StreamBuilder<List<ConnectivityResult>>(
      //   stream: Connectivity().onConnectivityChanged,
      //   builder: (context, snapshot) {
      //     final hasInternet =
      //         snapshot.hasData &&
      //         !snapshot.data!.contains(ConnectivityResult.none);

      //     if (!hasInternet) {
      //       return buildNoInternet(context);
      //     }

      //     return SizedBox.shrink();
      //   },
      // ),
    ],
  );
}

Widget _buildSedekah(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SadaqahListView()),
      );
    },
    child: Column(
      children: [
        Image.asset('assets/icon/donation_icon.png', height: 50, width: 50),
        const SizedBox(height: 5),
        const Text("Sadaqah", style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _buildSadaqahReminder(BuildContext context) {
  if (DateTime.now().weekday != DateTime.friday) {
    return const SizedBox.shrink();
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12.0),
    child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SadaqahListView()),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.violet.withOpacity(0.9),
              AppColors.violet.withOpacity(0.6),
              const Color(0xFF9C27B0).withOpacity(0.8),
              const Color(0xFFE040FB).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 🟣 Left side text
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Sadaqah today',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'A small act today can change a life and multiply your reward in the Hereafter.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: Image.asset(
                    'assets/images/front-view-homeless-man-holding-cup-with-coins_23-2148760767_1_-removebg-preview.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildQuran(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => QuranView()));
    },
    child: Column(
      children: [
        Image.asset('assets/icon/quran_icon.png', height: 50, width: 50),
        const SizedBox(height: 5),
        const Text("Quran", style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _buildHadith(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HadithBooksView()),
      );
    },
    child: Column(
      children: [
        Image.asset('assets/icon/hadith_icon.png', height: 50, width: 50),
        const SizedBox(height: 5),
        const Text("Hadith", style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _buildLocateMasjidNearby(
  BuildContext context,
  PrayerTimesProvider provider,
) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MasjidNearbyScreen(
            city: provider.city ?? "",
            country: provider.country ?? "",
          ),
        ),
      );
    },
    child: Column(
      children: [
        Image.asset('assets/icon/masjid_icon.png', height: 50, width: 50),
        const SizedBox(height: 5),
        const Text(
          "Nearby Mosque",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

Widget _buildQiblaFinder(BuildContext context, PrayerTimesProvider provider) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QiblaCompassView(
            city: provider.city ?? "",
            country: provider.country ?? "",
          ),
        ),
      );
    },
    child: Column(
      children: [
        Image.asset('assets/icon/kaaba_icon.png', height: 50, width: 50),
        SizedBox(height: 5),
        Text("Qibla Finder", style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _buildIslamicCalendar(
  BuildContext context,
  PrayerTimesProvider provider,
) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => IslamicCalendarView()),
      );
    },
    child: Column(
      children: [
        Image.asset(
          'assets/icon/islamic_calendar_icon.png',
          height: 50,
          width: 50,
        ),
        SizedBox(height: 5),
        Text("Islamic Calendar", style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _buildLocateMe(BuildContext context, PrayerTimesProvider provider) {
  return GestureDetector(
    onTap: () async {
      Navigator.pop(context);
      await provider.locateMe();
    },
    child: const Text(
      'Locate me instead',
      style: TextStyle(decoration: TextDecoration.underline),
    ),
  );
}

Widget _buildBookmark(BuildContext context) {
  final provider = context.watch<BookmarkProvider>();

  if (provider.bookmarks.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTitleText("Your Bookmarks"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: CircleAvatar(
              backgroundColor: AppColors.betterGray.withOpacity(0.3),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailsBookmarkView()),
                  );
                },
                child: Icon(
                  Icons.arrow_forward,
                  color: AppColors.violet.withOpacity(1),
                ),
              ),
            ),
          ),
        ],
      ),
      SizedBox(
        height: 90,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: provider.bookmarks.length,
          itemBuilder: (context, index) {
            return _buildBookmarkCard(context, provider.bookmarks[index]);
          },
        ),
      ),
    ],
  );
}

Widget _buildBookmarkCard(BuildContext context, String bookmark) {
  final qProvider = Provider.of<QuranProvider>(context, listen: false);

  if (bookmark.startsWith("page:")) {
    final page = int.tryParse(bookmark.split(":")[1]) ?? 0;
    final pagesMap = qProvider.getQuranPages();
    final pageVerses = pagesMap[page];
    final firstSurahName = (pageVerses != null && pageVerses.isNotEmpty)
        ? quran.getSurahName(pageVerses.first['surah']!)
        : 'Unknown';

    return _bookmarkContainer(
      context,
      title: "Page $page",
      subtitle: firstSurahName,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuranPageView(pageNumber: page)),
        );
      },
    );
  }

  if (bookmark.startsWith("hadith:")) {
    final parts = bookmark.split(":");

    if (parts.length < 4) return const SizedBox.shrink();

    final bookSlug = parts[1];
    final chapterId = parts[2];
    final hadithId = parts[3];

    return _bookmarkContainer(
      context,
      title: "Hadith #$hadithId",
      subtitle: bookSlug.replaceAll("-", " ").toUpperCase(),
      onTap: () {
        print(
          'Opening hadith → book: $bookSlug | chapter: $chapterId | hadith: $hadithId',
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HadithView(
              bookSlug: bookSlug,
              chapterId: chapterId,
              hadithId: hadithId,
            ),
          ),
        );
      },
    );
  }

  final parts = bookmark.split(":");
  if (parts.length < 2) return const SizedBox.shrink();
  final surahNum = int.tryParse(parts[0]) ?? 0;
  final verseNum = int.tryParse(parts[1]) ?? 0;
  final surahName = quran.getSurahName(surahNum);

  return _bookmarkContainer(
    context,
    title: "$surahName : $verseNum",
    subtitle: "Verse",
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SurahDetailView(surahNumber: surahNum, initialVerse: verseNum),
        ),
      );
    },
  );
}

Widget _bookmarkContainer(
  BuildContext context, {
  required String title,
  String? subtitle,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.violet, width: 1.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (subtitle != null)
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    ),
  );
}

void _showLocationBottomSheet(
  BuildContext context,
  PrayerTimesProvider provider,
) {
  showModalBottomSheet(
    backgroundColor: Colors.white,
    context: context,
    isScrollControlled: true,
    isDismissible: provider.times != null,
    enableDrag: provider.times != null,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return ChangeNotifierProvider(
        create: (_) => LocationInputProvider(),
        child: Consumer<LocationInputProvider>(
          builder: (context, locationProvider, _) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInsertText(),
                  const SizedBox(height: 20),
                  CustomTextField(
                    backgroundColor: AppColors.lightGray.withOpacity(1),
                    label: "City",
                    onChanged: locationProvider.setCity,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    label: "Country",
                    onChanged: locationProvider.setCountry,
                    backgroundColor: AppColors.lightGray.withOpacity(1),
                  ),
                  const SizedBox(height: 20),
                  _buildLocateMe(context, provider),
                  const SizedBox(height: 10),
                  CustomButton(
                    text: "Find your prayer times",
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                    onTap: locationProvider.isButtonEnabled
                        ? () {
                            Navigator.pop(context);
                            provider.fetchPrayerTimes(
                              locationProvider.city,
                              locationProvider.country,
                            );
                          }
                        : null,
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

void _showPrayerTimesDate(BuildContext context, PrayerTimesProvider provider) {
  final content = AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark,
    child: Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Consumer<PrayerTimesProvider>(
          builder: (context, provider, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        provider.setSelectedDate(
                          provider.selectedDate.subtract(
                            const Duration(days: 1),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) {
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildCustomCalendar(context),
                              );
                            },
                          );
                        },
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                "${provider.hijriDateModel!.gregorianDay}, ${provider.hijriDateModel!.gregorianDayDate} ${provider.hijriDateModel!.gregorianMonth} ${provider.hijriDateModel!.gregorianYear} ",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              Text(
                                " ${provider.hijriDateModel!.hijriDay} ${provider.hijriDateModel!.hijriMonth} ${provider.hijriDateModel!.hijriYear} ",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        provider.setSelectedDate(
                          provider.selectedDate.add(const Duration(days: 1)),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (provider.isPrayerTimesLoading)
                  Center(
                    child: Column(
                      children: [
                        _buildPrayerTimesRow(
                          "Fajr",
                          provider.times!.fajr,
                          true,
                        ),
                        _buildPrayerTimesRow(
                          "Sunrise",
                          provider.times!.sunrise,
                          true,
                        ),
                        _buildPrayerTimesRow(
                          "Dhuhr",
                          provider.times!.dhuhr,
                          true,
                        ),
                        _buildPrayerTimesRow("Asr", provider.times!.asr, true),
                        _buildPrayerTimesRow(
                          "Maghrib",
                          provider.times!.maghrib,
                          true,
                        ),
                        _buildPrayerTimesRow(
                          "Isha",
                          provider.times!.isha,
                          true,
                        ),
                      ],
                    ),
                  )
                else if (provider.times != null)
                  Column(
                    children: [
                      _buildPrayerTimesRow("Fajr", provider.times!.fajr, false),
                      _buildPrayerTimesRow(
                        "Sunrise",
                        provider.times!.sunrise,
                        false,
                      ),
                      _buildPrayerTimesRow(
                        "Dhuhr",
                        provider.times!.dhuhr,
                        false,
                      ),
                      _buildPrayerTimesRow("Asr", provider.times!.asr, false),
                      _buildPrayerTimesRow(
                        "Maghrib",
                        provider.times!.maghrib,
                        false,
                      ),
                      _buildPrayerTimesRow("Isha", provider.times!.isha, false),
                    ],
                  )
                else if (provider.error != null)
                  Text(provider.error!)
                else
                  const Text("No data"),
              ],
            );
          },
        ),
      ),
    ),
  );

  if (Theme.of(context).platform == TargetPlatform.iOS) {
    showCupertinoSheet(
      context: context,
      builder: (context) => Material(child: content),
    ).whenComplete(() {
      provider.setSelectedDate(provider.activeDate);

      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    });
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => content,
    ).whenComplete(() {
      provider.setSelectedDate(provider.activeDate);

      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    });
  }
}

void showProgrammeField(
  BuildContext context,
  MasjidProgrammeProvider provider,
) {
  // final prayerTimesProvider = Provider.of<PrayerTimesProvider>(
  //   context,
  //   listen: false,
  // );
  final pageController = PageController();

  final content = StatefulBuilder(
    builder: (context, setState) {
      pageController.addListener(() {
        setState(() {});
      });
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          bottomNavigationBar: Consumer<MasjidProgrammeProvider>(
            builder: (context, programmeProvider, _) {
              final onPageTwo =
                  pageController.hasClients &&
                  pageController.page?.round() == 1;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0, -1),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: CustomButton(
                  onTap: onPageTwo
                      ? (programmeProvider.isFormValid
                            ? () async {
                                await programmeProvider.addProgramme();
                                programmeProvider.resetForm();

                                Navigator.pop(context);
                                CustomPillSnackbar.show(
                                  context,
                                  message:
                                      '✅ Programme submitted successfully!',
                                );
                              }
                            : null)
                      : () {
                          pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                  backgroundColor: onPageTwo && !programmeProvider.isFormValid
                      ? Colors.grey
                      : Colors.black,
                  text: onPageTwo ? 'Submit' : 'Review your details',
                  textColor: Colors.white,
                ),
              );
            },
          ),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // PAGE 1
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTitleText('🕌  Benefits of Adding Mosque Programme'),
                    const SizedBox(height: 12),
                    _buildContainer(),
                    const SizedBox(height: 12),
                    _buildOneOffPayment(context),
                  ],
                ),

                // PAGE 2 (Form)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildTitleTextBottomSheet('Masjid Name'),
                            CustomTextField(
                              controller: provider.masjidController,
                              label: 'Masjid Name',
                            ),

                            _buildTitleTextBottomSheet('Poster'),
                            GestureDetector(
                              onTap: () async {
                                await provider.pickPoster();
                              },
                              child: Consumer<MasjidProgrammeProvider>(
                                builder: (context, provider, _) {
                                  return DottedBorder(
                                    options: RoundedRectDottedBorderOptions(
                                      color: Colors.grey.shade400,
                                      strokeWidth: 1,
                                      dashPattern: [6, 3],
                                      radius: const Radius.circular(10),
                                      padding: const EdgeInsets.all(0),
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 150,

                                      child: provider.posterBase64 == null
                                          ? const Center(
                                              child: Text("Upload a poster"),
                                            )
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.memory(
                                                base64Decode(
                                                  provider.posterBase64!,
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            _buildTitleTextBottomSheet('Programme Title'),
                            CustomTextField(
                              controller: provider.titleController,
                              label: 'Title',
                            ),

                            _buildTitleTextBottomSheet('Date & Time'),
                            GestureDetector(
                              onTap: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: now,
                                  firstDate: now,
                                  lastDate: now.add(const Duration(days: 7)),
                                );

                                if (picked != null) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );

                                  if (time != null) {
                                    setState(() {
                                      provider.dateTime = DateTime(
                                        picked.year,
                                        picked.month,
                                        picked.day,
                                        time.hour,
                                        time.minute,
                                      );
                                    });
                                  }
                                }
                              },
                              child: Container(
                                alignment: Alignment.bottomLeft,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  provider.dateTime != null
                                      ? DateFormat(
                                          "d MMM yyyy, h:mm a",
                                        ).format(provider.dateTime!)
                                      : "Select Date & Time",
                                  style: TextStyle(
                                    color: provider.dateTime == null
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Online Programme"),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      provider.isOnline = !provider.isOnline;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    child: provider.isOnline
                                        ? Container(
                                            width: 16,
                                            height: 16,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.black,
                                            ),
                                          )
                                        : const SizedBox(width: 16, height: 16),
                                  ),
                                ),
                              ],
                            ),
                            if (provider.isOnline) ...[
                              _buildTitleTextBottomSheet('Join Link'),
                              CustomTextField(
                                controller: provider.joinLinkController,
                                label: 'Join Link (Zoom/YouTube)',
                                keyboardType: TextInputType.url,
                              ),
                            ] else ...[
                              _buildTitleTextBottomSheet('Location'),
                              CustomTextField(
                                controller: provider.locationController,
                                label: 'eg: Shah Alam, Selangor',
                              ),
                            ],

                            const SizedBox(height: 20),
                            _buildContainerReminder(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  if (Theme.of(context).platform == TargetPlatform.iOS) {
    showCupertinoSheet(
      context: context,
      builder: (context) => Material(child: content),
    ).whenComplete(() {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    });
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => content,
    ).whenComplete(() {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    });
  }
}

Widget _buildOneOffPayment(BuildContext context) {
  final programmeProvider = context.watch<MasjidProgrammeProvider>();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('One-off Payment', style: TextStyle(fontSize: 14)),
      Text(
        'RM ${formatCurrency(programmeProvider.oneOffAmount)}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
      ),
      SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.violet.withOpacity(0.1),
          border: Border.all(color: AppColors.violet.withOpacity(1)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Your payment supports app maintenance and improvements.',
          style: TextStyle(
            color: AppColors.violet.withOpacity(1),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}

Widget _buildContainer() {
  return Container(
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        _buildDescriptionText(
          "Promote your masjid's events to nearby communities, including communal work, after-prayer lectures, Quran classes, and youth programmes.\n\n"
          "Increase attendance and engagement for kuliah, tazkirah, and special events like qiyamullail or Eid celebrations.\n\n"
          "Help Muslims discover beneficial activities happening around them.\n\n"
          "Strengthen community ties through shared learning, worship, and service.\n\n"
          "Reach younger audiences who rely on mobile apps for updates.\n\n"
          "Build trust and visibility by being part of a verified Islamic platform.",
        ),
      ],
    ),
  );
}

Widget _buildContainerReminder() {
  return Container(
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.violet.withOpacity(1), width: 3),
    ),
    child: Column(
      children: [
        _buildDescriptionText(
          "Your programme will be automatically removed after its date.\n\n"
          "It will take 1-2 days to approve your programme.",
        ),
      ],
    ),
  );
}

Widget _buildDescriptionText(String name) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Text(
      name,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    ),
  );
}

// Widget _buildCustomCalendar(BuildContext context) {
//   return Consumer<PrayerTimesProvider>(
//     builder: (context, provider, _) {
//       return ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//           child: Container(
//             height: 400,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(20),
//               gradient: LinearGradient(
//                 colors: [
//                   Colors.white.withOpacity(0.7),
//                   Colors.white.withOpacity(0.4),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               border: Border.all(
//                 color: Colors.white.withOpacity(0.8),
//                 width: 1.5,
//               ),
//             ),
//             child: TableCalendar(
//               firstDay: DateTime(2000),
//               lastDay: DateTime(2100),
//               focusedDay: provider.selectedDate,
//               startingDayOfWeek: StartingDayOfWeek.monday,
//               calendarFormat: CalendarFormat.month,
//               headerStyle: HeaderStyle(
//                 titleCentered: true,
//                 formatButtonVisible: false,
//                 titleTextStyle: const TextStyle(
//                   color: Colors.black,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 leftChevronIcon: const Icon(
//                   Icons.arrow_back,
//                   color: Colors.black,
//                 ),
//                 rightChevronIcon: const Icon(
//                   Icons.arrow_forward,
//                   color: Colors.black,
//                 ),
//               ),
//               calendarStyle: CalendarStyle(
//                 todayDecoration: BoxDecoration(
//                   color: AppColors.lightGray.withOpacity(1),
//                   shape: BoxShape.circle,
//                 ),
//                 selectedDecoration: BoxDecoration(
//                   color: AppColors.violet.withOpacity(1),
//                   shape: BoxShape.circle,
//                 ),
//                 selectedTextStyle: const TextStyle(color: Colors.white),
//                 todayTextStyle: const TextStyle(color: Colors.black),
//                 weekendTextStyle: const TextStyle(color: Colors.black87),
//                 defaultTextStyle: const TextStyle(color: Colors.black),
//                 outsideDaysVisible: false,
//               ),
//               selectedDayPredicate: (day) =>
//                   isSameDay(provider.selectedDate, day),
//               onDaySelected: (selectedDay, focusedDay) {
//                 provider.setSelectedDate(selectedDay);
//               },
//             ),
//           ),
//         ),
//       );
//     },
//   );
// }

Widget _buildCustomCalendar(BuildContext context) {
  return Consumer<PrayerTimesProvider>(
    builder: (context, provider, _) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.7),
                  Colors.white.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 1.5,
              ),
            ),
            child: TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: provider.focusedDate, // ✅ track current visible month
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarFormat: CalendarFormat.month,

              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                leftChevronIcon: Icon(Icons.arrow_back, color: Colors.black),
                rightChevronIcon: Icon(
                  Icons.arrow_forward,
                  color: Colors.black,
                ),
              ),

              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),

              onDaySelected: (selectedDay, focusedDay) {
                provider.setPickerSelectedDate(selectedDay);
                provider.setFocusedDate(focusedDay);
              },

              onPageChanged: (focusedDay) {
                provider.setFocusedDate(focusedDay);
              },

              selectedDayPredicate: (day) =>
                  isSameDay(provider.pickerSelectedDate, day),
            ),
          ),
        ),
      );
    },
  );
}

// Widget _buildCustomTimePicker(
//   BuildContext context,
//   PrayerTimesProvider provider,
//   // MasjidProgrammeProvider masjidProvider
// ) {
//   int selectedHour = provider.pickerSelectedTime?.hour ?? TimeOfDay.now().hour;
//   int selectedMinute =
//       provider.pickerSelectedTime?.minute ?? TimeOfDay.now().minute;

//   FixedExtentScrollController hourController = FixedExtentScrollController(
//     initialItem: selectedHour,
//   );
//   FixedExtentScrollController minuteController = FixedExtentScrollController(
//     initialItem: selectedMinute,
//   );

//   return Container(
//     height: 200,
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(20),
//       color: Colors.white.withOpacity(0.8),
//       boxShadow: [
//         BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
//       ],
//     ),
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         // Hours picker
//         Expanded(
//           child: ListWheelScrollView.useDelegate(
//             controller: hourController,
//             itemExtent: 40,
//             perspective: 0.005,
//             onSelectedItemChanged: (index) {
//               selectedHour = index;
//               provider.setPickerSelectedTime(
//                 TimeOfDay(hour: selectedHour, minute: selectedMinute),
//               );
//             },
//             childDelegate: ListWheelChildBuilderDelegate(
//               builder: (context, index) {
//                 if (index < 0 || index > 23) return null;
//                 return Center(
//                   child: Text(
//                     index.toString().padLeft(2, '0'),
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//         const Text(
//           ":",
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//         // Minutes picker
//         Expanded(
//           child: ListWheelScrollView.useDelegate(
//             controller: minuteController,
//             itemExtent: 40,
//             perspective: 0.005,
//             onSelectedItemChanged: (index) {
//               selectedMinute = index;
//               provider.setPickerSelectedTime(
//                 TimeOfDay(hour: selectedHour, minute: selectedMinute),
//               );
//             },
//             childDelegate: ListWheelChildBuilderDelegate(
//               builder: (context, index) {
//                 if (index < 0 || index > 59) return null;
//                 return Center(
//                   child: Text(
//                     index.toString().padLeft(2, '0'),
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  final double minExtent;
  @override
  final double maxExtent;
  final Widget Function(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  )
  builder;

  _HeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.builder,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => builder(context, shrinkOffset, overlapsContent);

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) => true;
}

Future<void> updatePrayerWidget(PrayerTimesProvider provider) async {
  if (provider.times == null || provider.nextPrayerDate == null) return;

  await HomeWidget.saveWidgetData('fajr', provider.times?.fajr ?? "--");
  await HomeWidget.saveWidgetData('sunrise', provider.times?.sunrise ?? "--");
  await HomeWidget.saveWidgetData('dhuhr', provider.times?.dhuhr ?? "--");
  await HomeWidget.saveWidgetData('asr', provider.times?.asr ?? "--");
  await HomeWidget.saveWidgetData('maghrib', provider.times?.maghrib ?? "--");
  await HomeWidget.saveWidgetData('isha', provider.times?.isha ?? "--");

  await HomeWidget.saveWidgetData('next_prayer', provider.nextPrayerText);
  await HomeWidget.saveWidgetData(
    'next_prayer_timestamp',
    provider.nextPrayerDate!.millisecondsSinceEpoch,
  );

  await HomeWidget.updateWidget(
    iOSName: 'PrayerTimeWidget',
    androidName: 'PrayerTimeWidget',
  );
}

Future<void> schedulePrayerNotifications(PrayerTimesProvider provider) async {
  await flutterLocalNotificationsPlugin.cancelAll();
  if (provider.times == null) return;

  void schedulePrayer(int id, String name, String time) {
    final prayerTime = parsePrayerTime(time);

    final now = DateTime.now();

    final reminderTime = prayerTime.subtract(const Duration(minutes: 20));
    if (reminderTime.isAfter(now)) {
      scheduleNotification(
        id: id * 10,
        title: "$name Reminder",
        body: "$name prayer will be in 20 minutes",
        scheduledDate: reminderTime,
        playAdhan: false,
      );
    }

    if (prayerTime.isAfter(now)) {
      scheduleNotification(
        id: id * 10 + 1,
        title: "Prayer Time",
        body: "It's time for $name",
        scheduledDate: prayerTime,
        playAdhan: true,
      );
    }
  }

  schedulePrayer(1, "Fajr", provider.times!.fajr);
  schedulePrayer(1, "Sunrise", provider.times!.sunrise);
  schedulePrayer(2, "Dhuhr", provider.times!.dhuhr);
  schedulePrayer(3, "Asr", provider.times!.asr);
  schedulePrayer(4, "Maghrib", provider.times!.maghrib);
  schedulePrayer(5, "Isha", provider.times!.isha);
}

Future<Map<String, dynamic>> loadSadaqahData() async {
  final jsonString = await rootBundle.loadString(
    'assets/data/hadith_quran_sadaqah.json',
  );
  return json.decode(jsonString);
}

Future<void> scheduleSadaqahReminder() async {
  final data = await loadSadaqahData();
  final sadaqahRefs = [
    ...data['sadaqahReferences']['quranVerses'],
    ...data['sadaqahReferences']['hadiths'],
  ];

  final random = Random();
  final ref = sadaqahRefs[random.nextInt(sadaqahRefs.length)];

  final String title = "Sadaqah Reminder";
  final String body =
      ref['translation'] ?? "Give charity today for the sake of Allah.";

  final now = tz.TZDateTime.now(tz.local);
  var friday = tz.TZDateTime(tz.local, now.year, now.month, now.day, 12, 0);

  while (friday.weekday != DateTime.friday || friday.isBefore(now)) {
    friday = friday.add(const Duration(days: 1));
  }

  await flutterLocalNotificationsPlugin.zonedSchedule(
    999,
    title,
    body,
    friday,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'sadaqah_channel_id',
        'Sadaqah Notifications',
        channelDescription: 'Weekly sadaqah reminders on Fridays',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );
}

Future<void> cancelPrayerNotifications() async {
  // If you gave prayer notifications IDs like 1–99, cancel those only
  for (int id = 1; id <= 100; id++) {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}

Future<void> cancelSadaqahNotifications() async {
  await flutterLocalNotificationsPlugin.cancel(999);
}
