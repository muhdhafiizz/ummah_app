import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:ramadhan_companion_app/firebase_options.dart';
import 'package:ramadhan_companion_app/helper/local_notifications.dart';
import 'package:ramadhan_companion_app/provider/bookmark_provider.dart';
import 'package:ramadhan_companion_app/provider/calendar_provider.dart';
import 'package:ramadhan_companion_app/provider/carousel_provider.dart';
import 'package:ramadhan_companion_app/provider/doa_zikir_provider.dart';
import 'package:ramadhan_companion_app/provider/hadith_chapters_provider.dart';
import 'package:ramadhan_companion_app/provider/hadith_books_provider.dart';
import 'package:ramadhan_companion_app/provider/hadith_provider.dart';
import 'package:ramadhan_companion_app/provider/islamic_calendar_provider.dart';
import 'package:ramadhan_companion_app/provider/location_input_provider.dart';
import 'package:ramadhan_companion_app/provider/login_provider.dart';
import 'package:ramadhan_companion_app/provider/masjid_nearby_provider.dart';
import 'package:ramadhan_companion_app/provider/masjid_programme_provider.dart';
import 'package:ramadhan_companion_app/provider/notifications_provider.dart';
import 'package:ramadhan_companion_app/provider/notifications_settings_provider.dart';
import 'package:ramadhan_companion_app/provider/prayer_times_provider.dart';
import 'package:ramadhan_companion_app/provider/qibla_finder_provider.dart';
import 'package:ramadhan_companion_app/provider/quran_provider.dart';
import 'package:ramadhan_companion_app/provider/sadaqah_provider.dart';
import 'package:ramadhan_companion_app/provider/signup_provider.dart';
import 'package:ramadhan_companion_app/provider/webview_provider.dart';
import 'package:ramadhan_companion_app/ui/login_view.dart';
import 'package:ramadhan_companion_app/ui/prayer_times_view.dart';
import 'package:ramadhan_companion_app/widgets/app_colors.dart';
import 'package:ramadhan_companion_app/widgets/custom_loading_dialog.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await HomeWidget.setAppGroupId('group.com.ramadhan_companion_app.pr');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SignupProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => PrayerTimesProvider()),
        ChangeNotifierProvider(create: (_) => LocationInputProvider()),
        ChangeNotifierProvider(create: (_) => CarouselProvider()),
        ChangeNotifierProvider(create: (_) => MasjidNearbyProvider()),
        ChangeNotifierProvider(create: (_) => QiblaProvider()),
        ChangeNotifierProvider(create: (_) => IslamicCalendarProvider()),
        ChangeNotifierProvider(create: (_) => QuranProvider(1)),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final sadaqahProvider = SadaqahProvider();
            sadaqahProvider.fetchUserRole();
            return sadaqahProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => DateProvider()),
        ChangeNotifierProvider(create: (_) => HadithBooksProvider()),
        ChangeNotifierProvider(create: (_) => HadithChaptersProvider()),
        ChangeNotifierProvider(create: (_) => HadithProvider()),
        ChangeNotifierProvider(create: (_) => PaymentWebViewProvider()),
        ChangeNotifierProvider(create: (_) => MasjidProgrammeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationSettingsProvider()),
        ChangeNotifierProvider(create: (_) => DoaProvider()),
        ChangeNotifierProvider(
          create: (context) {
            final role = context.read<SadaqahProvider>().role ?? 'user';
            final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
            return NotificationsProvider(role, userId);
          },
        ),
      ],
      child: const MainApp(),
    ),
  );

  tz.initializeTimeZones();

  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

  const InitializationSettings initSettings = InitializationSettings(
    android: initSettingsAndroid,
    iOS: initSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);
  await requestNotificationPermissions();
  final prayerProvider = PrayerTimesProvider();
  await prayerProvider.initialize();
  // await requestExactAlarmPermission();
  await schedulePrayerNotifications(prayerProvider);
  await scheduleSadaqahReminder();
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Liter',
        scaffoldBackgroundColor: AppColors.lightGray.withOpacity(1),
        cupertinoOverrideTheme: const CupertinoThemeData(
          primaryColor: CupertinoColors.activeBlue,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingDialog());
        }
        if (snapshot.hasData) {
          return PrayerTimesView();
        }
        return LoginView();
      },
    );
  }
}

Widget buildNoInternet(BuildContext context) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(8),
    color: Colors.red,
    child: const Text(
      'No internet connection',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}
