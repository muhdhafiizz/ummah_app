import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ramadhan_companion_app/provider/masjid_nearby_provider.dart';
import 'package:ramadhan_companion_app/widgets/app_colors.dart';
import 'package:ramadhan_companion_app/widgets/custom_button.dart';
import 'package:ramadhan_companion_app/widgets/custom_pill_snackbar.dart';
import 'package:ramadhan_companion_app/widgets/shimmer_loading.dart';

class MasjidNearbyScreen extends StatelessWidget {
  final String city;
  final String country;

  const MasjidNearbyScreen({
    super.key,
    required this.city,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MasjidNearbyProvider>();

    if (!provider.isLoading &&
        (provider.masjids.isEmpty ||
            provider.originCity != city ||
            provider.originCountry != country)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.fetchMasjidsFromAddress(city, country);
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildAppBar(context),
              const SizedBox(height: 10),
              provider.isLoading
                  ? Expanded(child: Center(child: _buildShimmerLoading()))
                  : provider.errorMessage != null
                  ? Expanded(child: Center(child: Text(provider.errorMessage!)))
                  : Expanded(
                      child: ListView.builder(
                        itemCount: provider.masjids.length,
                        itemBuilder: (context, index) {
                          final masjid = provider.masjids[index];
                          final distance = provider.calculateDistance(
                            provider.originLat!,
                            provider.originLng!,
                            masjid.latitude,
                            masjid.longitude,
                          );
                          return _buildMasjidCard(
                            context: context,
                            name: masjid.name,
                            photoReference: masjid.photoReference,
                            town: masjid.city,
                            state: masjid.state,
                            distanceKm: distance,
                            ratings: masjid.rating ?? 0,
                            latitude: masjid.latitude,
                            longitude: masjid.longitude,
                            building: masjid.building,
                            denomination: masjid.denomination,
                            wheelchair: masjid.wheelchair,
                            provider: provider,
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildAppBar(BuildContext context) {
  return Row(
    children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Icon(Icons.arrow_back),
      ),
      SizedBox(width: 10),
      Text(
        "Nearby Mosque",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
      ),
    ],
  );
}

Widget _buildShimmerLoading() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(4, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: ShimmerLoadingWidget(height: 150, width: double.infinity),
      );
    }),
  );
}

Widget _buildMasjidCard({
  required BuildContext context,
  required String name,
  required List<String> photoReference,
  required double distanceKm,
  required String town,
  required String state,
  required double ratings,
  required double latitude,
  required double longitude,
  required String? building,
  required String? denomination,
  required String? wheelchair,
  required MasjidNearbyProvider provider,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20.0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 Masjid Info
            Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(width: 5),
                if (building == 'yes' ||
                    building == 'mosque' ||
                    denomination == 'sunni')
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.green[100],
                    ),
                    child: Icon(Icons.mosque, size: 14, color: Colors.green),
                  ),
                SizedBox(width: 5),
                if (wheelchair == 'yes')
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.blue[100],
                    ),
                    child: Icon(Icons.accessible, size: 14, color: Colors.blue),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "${distanceKm.toStringAsFixed(2)} km away",
              style: const TextStyle(color: Colors.black38, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              "📍 $town, $state",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),

            // 🔹 Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButton(
                  onTap: () async {
                    final accounts = await provider.loadMasjidAccounts(context);
                    final matched = provider.findClosestMatch(name, accounts);

                    _showAccountDetails(context, matched);
                  },
                  iconData: Icons.volunteer_activism_outlined,
                  text: 'Earn Jannah',
                  textColor: Colors.white,
                  backgroundColor: AppColors.violet.withOpacity(1),
                ),
                const SizedBox(width: 10),
                CustomButton(
                  onTap: () => _showNavigationOptions(
                    context,
                    name,
                    latitude,
                    longitude,
                    provider,
                  ),
                  iconData: Icons.map_outlined,
                  text: 'Go there',
                  borderColor: AppColors.violet.withOpacity(1),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

void _showAccountDetails(BuildContext context, dynamic matched) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      if (matched != null) {
        return Container(
          width: double.infinity, // ✅ full width
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                matched.masjidName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(matched.bankName, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              const Text("Account Number"),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: matched.accNum));
                  Navigator.pop(context);
                  CustomPillSnackbar.show(
                    context,
                    message: "✅ Account number copied",
                  );
                },
                child: Text(
                  matched.accNum,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Text("No donation info found for this masjid"),
        );
      }
    },
  );
}

void _showNavigationOptions(
  BuildContext context,
  String name,
  double lat,
  double lng,
  MasjidNearbyProvider provider,
) {
  if (Platform.isIOS) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(name),
        message: const Text('Open location in maps'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await provider.openMap(lat, lng);
            },
            child: const Text('Open in Maps'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                title: const Text("Open in Google Maps / Waze"),
                onTap: () async {
                  Navigator.pop(context);
                  await provider.openMap(lat, lng);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
