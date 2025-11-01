import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ramadhan_companion_app/provider/login_provider.dart';
import 'package:ramadhan_companion_app/provider/masjid_programme_provider.dart';
import 'package:ramadhan_companion_app/provider/prayer_times_provider.dart';
import 'package:ramadhan_companion_app/provider/sadaqah_provider.dart';
import 'package:ramadhan_companion_app/ui/details_bookmark_view.dart';
import 'package:ramadhan_companion_app/ui/login_view.dart';
import 'package:ramadhan_companion_app/ui/notifications_settings_view.dart';
import 'package:ramadhan_companion_app/ui/prayer_times_view.dart';
import 'package:ramadhan_companion_app/ui/sadaqah_view.dart';
import 'package:ramadhan_companion_app/ui/submission_status_view.dart';
import 'package:ramadhan_companion_app/ui/webview_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final prayerTimesProvider = context.watch<PrayerTimesProvider>();
    final sadaqahProvider = context.watch<SadaqahProvider>();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle = isDarkMode
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopNav(context),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: [
                      _buildEmailandRole(sadaqahProvider),
                      const SizedBox(height: 10),
                      _buildListTile(
                        context,
                        title: 'List your organization',
                        icon: Icons.business_outlined,
                        onTap: () {
                          showSadaqahField(context, sadaqahProvider);
                        },
                      ),
                      _buildListTile(
                        context,
                        title: 'Add nearby masjid programme',
                        icon: Icons.event_outlined,
                        onTap: () {
                          final programmeProvider =
                              Provider.of<MasjidProgrammeProvider>(
                                context,
                                listen: false,
                              );
                          showProgrammeField(context, programmeProvider);
                        },
                      ),
                      _buildListTile(
                        context,
                        title: 'Submission status',
                        icon: Icons.assignment_turned_in_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MySubmissionsPage(),
                            ),
                          );
                        },
                      ),
                      _buildListTile(
                        context,
                        title: 'Notifications',
                        icon: Icons.notifications_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsSettingsView(),
                            ),
                          );
                        },
                      ),
                      _buildListTile(
                        context,
                        title: 'Your bookmark',
                        icon: Icons.bookmark_outline,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DetailsBookmarkView(),
                            ),
                          );
                        },
                      ),
                      _buildListTile(
                        context,
                        title: 'Write a feedback',
                        icon: Icons.feedback_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WebViewPage(
                                url: 'https://forms.gle/d5iGkj6y32JaptDf7',
                                title: 'Feedback',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      _showLogoutConfirmation(context, prayerTimesProvider),
                  child: const Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      'Log out',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildTopNav(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back),
      ),
      const SizedBox(height: 20),
      const Text(
        "Settings",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
      ),
    ],
  );
}

Widget _buildEmailandRole(SadaqahProvider sadaqahProvider) {
  final role = sadaqahProvider.role ?? 'user';
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return const Center(child: Text("Not logged in"));
  }

  final isSuperAdmin = role == 'super_admin';

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('sadaqah_orgs')
        .where('submittedBy', isEqualTo: user.uid)
        .snapshots(),
    builder: (context, snapshot) {
      // int totalSubmitted = 0;
      int totalPaid = 0;

      if (snapshot.hasData) {
        final docs = snapshot.data!.docs;
        // totalSubmitted = docs.length;
        totalPaid = docs
            .where(
              (d) => (d.data() as Map<String, dynamic>)['status'] == 'paid',
            )
            .length;
      }

      return Container(
        padding: const EdgeInsets.all(12),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🧍 LEFT: User info
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  user.displayName ?? "--",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? "No email",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSuperAdmin
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    border: Border.all(
                      color: isSuperAdmin ? Colors.orange : Colors.green,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      color: isSuperAdmin ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // 🧍‍♂️ VERTICAL DIVIDER
            const SizedBox(
              height: 80,
              child: VerticalDivider(
                color: Colors.black54,
                thickness: 1,
                width: 20,
              ),
            ),

            // 📊 RIGHT: Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _buildStatBox("Total Submitted", totalSubmitted, Colors.blue),
                // const SizedBox(height: 8),
                _buildStatBox("Organizations", totalPaid),
              ],
            ),
          ],
        ),
      );
    },
  );
}

// Small helper widget for showing stat boxes
Widget _buildStatBox(String title, int count) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "$count",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      const Divider(color: Colors.black54, thickness: 0.5),
    ],
  );
}

Widget _buildListTile(
  BuildContext context, {
  required String title,
  required VoidCallback onTap,
  required IconData icon,
}) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
    onTap: onTap,
  );
}

void _showLogoutConfirmation(
  BuildContext context,
  PrayerTimesProvider provider,
) {
  if (Platform.isIOS) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Log out'),
        message: const Text('Are you sure you want to log out?'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              provider.logout();
              context.read<SadaqahProvider>().resetRole();
              context.read<LoginProvider>().resetLoginState();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginView()),
              );
            },
            isDestructiveAction: true,
            child: const Text('Log out'),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            children: [
              const ListTile(
                title: Text(
                  'Log out',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text('Are you sure you want to log out?'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Log out'),
                onTap: () {
                  Navigator.pop(context);
                  provider.logout();
                  context.read<SadaqahProvider>().resetRole();
                  context.read<LoginProvider>().resetLoginState();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginView()),
                  );
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
