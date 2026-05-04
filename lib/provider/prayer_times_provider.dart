import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:ramadhan_companion_app/model/hijri_date_model.dart';
import 'package:ramadhan_companion_app/model/news_model.dart';
import 'package:ramadhan_companion_app/model/prayer_times_model.dart';
import 'package:ramadhan_companion_app/model/quran_daily_model.dart';
import 'package:ramadhan_companion_app/model/random_hadith_model.dart';
import 'package:ramadhan_companion_app/service/hijri_date_service.dart';
import 'package:ramadhan_companion_app/service/news_service.dart';
import 'package:ramadhan_companion_app/service/prayer_times_service.dart';
import 'package:ramadhan_companion_app/service/quran_daily_service.dart';
import 'package:ramadhan_companion_app/service/random_hadith_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerTimesProvider extends ChangeNotifier {
  bool _isPrayerTimesLoading = false;
  final bool _isQuranVerseLoading = false;
  final bool _isHijriDateLoading = false;
  bool _initialized = false;
  bool _shouldAskLocation = false;
  String? _error;
  String? _city;
  String? _country;
  String _countdownText = "";
  String _nextPrayerText = "";
  Timer? _countdownTimer;
  String? _hijriDate;
  String? _hijriDay;
  String? _hijriMonth;
  String? _hijriYear;
  DateTime? _nextPrayerDate;
  DateTime? _lastFetchedDate;
  DateTime _selectedDate = DateTime.now();
  DateTime _activeDate = DateTime.now();
  DateTime? _dateTime;
  DateTime? _pickerSelectedDate;
  DateTime _focusedDate = DateTime.now();

  TimeOfDay? _pickerSelectedTime;
  DateTime get selectedDate => _selectedDate;
  DateTime get activeDate => _activeDate;
  HijriDateModel? _hijriDateModel;
  // NewsModel? _newsModel;
  List<NewsItem> _newsModel = [];
  PrayerTimesModel? _times;
  QuranDailyModel? _quranDaily;
  RandomHadithModel? _hadithDaily;

  final quranService = QuranDailyService();
  final hadithService = RandomHadithService();

  bool get isPrayerTimesLoading => _isPrayerTimesLoading;
  bool get isQuranVerseLoading => _isQuranVerseLoading;
  bool get isHijriDateLoading => _isHijriDateLoading;
  bool get shouldAskLocation => _shouldAskLocation;
  String? get error => _error;
  String? get city => _city;
  String? get country => _country;
  String get countdownText => _countdownText;
  String get nextPrayerText => _nextPrayerText;
  String? get hijriDate => _hijriDate;
  String? get hijriDay => _hijriDay;
  String? get hijriMonth => _hijriMonth;
  String? get hijriYear => _hijriYear;
  DateTime? get nextPrayerDate => _nextPrayerDate;
  DateTime? get dateTime => _dateTime;
  DateTime get focusedDate => _focusedDate;
  DateTime? get pickerSelectedDate => _pickerSelectedDate;
  TimeOfDay? get pickerSelectedTime => _pickerSelectedTime;
  PrayerTimesModel? get times => _times;
  HijriDateModel? get hijriDateModel => _hijriDateModel;
  HijriDateModel? get activeHijriDateModel => _hijriDateModel;
  QuranDailyModel? get quranDaily => _quranDaily;
  RandomHadithModel? get hadithDaily => _hadithDaily;
  List<NewsItem> get newsModel => _newsModel;

  PrayerTimesProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _city = prefs.getString('city');
    _country = prefs.getString('country');

    if (_city != null && _country != null) {
      await fetchPrayerTimes(_city!, _country!);
    } else {
      _shouldAskLocation = true;
      notifyListeners();
    }
  }

  Future<void> fetchPrayerTimes(String city, String country) async {
    _isPrayerTimesLoading = true;
    _error = null;
    _city = city;
    _country = country;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('prayer_method');

      _times = await PrayerTimesService().getPrayerTimes(city, country);
      startCountdown();
      _hijriDateModel = await HijriDateService().getTodayHijriDate();

      await prefs.setString('city', city);
      await prefs.setString('country', country);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isPrayerTimesLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPrayerTimesByDate(
    String city,
    String country,
    DateTime date,
  ) async {
    _isPrayerTimesLoading = true;
    _error = null;
    notifyListeners();

    try {
      final formattedDate =
          "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";

      final url = Uri.parse(
        'https://api.aladhan.com/v1/timingsByCity/$formattedDate?city=$city&country=$country&method=2',
      );

      print("📡 Fetching prayer times for: $formattedDate");
      print("🌍 City: $city, Country: $country");
      print("🔗 URL: $url");

      final response = await http.get(url);
      print("📥 Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("✅ API success, data received");

        _times = PrayerTimesModel.fromJson(data);
        _hijriDateModel = await HijriDateService().getHijriDateByGregorian(
          date,
        );
      } else {
        print("❌ API failed: ${response.body}");
        throw Exception('Failed to load prayer times');
      }
    } catch (e) {
      print("💥 Error fetching prayer times: $e");
      _error = e.toString();
    } finally {
      _isPrayerTimesLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMuslimNews() async {
    print('fetchMuslimNews');
    try {
      final service = NewsService();
      _newsModel = await service.getMuslimNews();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to load Muslim News: $e');
    }
  }

  Future<void> clearCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('city');
    await prefs.remove('country');
    _city = null;
    _country = null;
    _times = null;
    _shouldAskLocation = true;
    notifyListeners();
  }

  Future<void> fetchHijriDate() async {
    try {
      _hijriDateModel = await HijriDateService().getTodayHijriDate();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> locateMe() async {
    _isPrayerTimesLoading = true;
    _error = null;
    notifyListeners();

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied");
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied");
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isEmpty) {
        throw Exception("Could not determine address from coordinates");
      }
      final placemark = placemarks.first;
      final area =
          placemark.thoroughfare ?? placemark.subAdministrativeArea ?? "";
      final city = placemark.locality ?? "";
      final country = placemark.country ?? "";
      print(placemark.locality);
      print(placemark.subAdministrativeArea);
      print(placemark.thoroughfare);

      final fullLocation = area.isNotEmpty ? "$area, $city" : city;

      if (city.isEmpty || country.isEmpty) {
        throw Exception("Could not determine city/country from location");
      }

      await fetchPrayerTimes(fullLocation, country);
      print(fullLocation);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isPrayerTimesLoading = false;
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    final today = DateTime.now();

    if (_lastFetchedDate == null ||
        _lastFetchedDate!.day != today.day ||
        _lastFetchedDate!.month != today.month ||
        _lastFetchedDate!.year != today.year) {
      await fetchRandomVerse();
      await fetchRandomHadith();
    }

    await fetchMuslimNews();
    await fetchHijriDate();
    _initialized = true;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    if (city != null && country != null) {
      fetchPrayerTimesByDate(city!, country!, _selectedDate);
    }
    notifyListeners();
  }

  void setFocusedDate(DateTime date) {
    _focusedDate = date;
    notifyListeners();
  }

  void confirmActiveDate() async {
    _activeDate = _selectedDate;

    if (city != null && country != null) {
      await fetchPrayerTimesByDate(city!, country!, _activeDate);
      _hijriDateModel = await HijriDateService().getHijriDateByGregorian(
        _activeDate,
      );
    }

    notifyListeners();
  }

  void setPickerSelectedDate(DateTime date) async {
    _pickerSelectedDate = date;
    _selectedDate = date;

    if (city != null && country != null) {
      await fetchPrayerTimesByDate(city!, country!, date);
      _hijriDateModel = await HijriDateService().getHijriDateByGregorian(date);
    }

    notifyListeners();
  }

  void setPickerSelectedTime(TimeOfDay time) {
    _pickerSelectedTime = time;
    notifyListeners();
  }

  void clearPickerSelection() {
    _pickerSelectedDate = null;
    _pickerSelectedTime = null;
  }

  set dateTime(DateTime? value) {
    _dateTime = value;
    notifyListeners();
  }

  Future<void> fetchRandomVerse() async {
    try {
      final verse = await quranService.getRandomVerse();
      _quranDaily = verse;
      _lastFetchedDate = DateTime.now();
      notifyListeners();
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> fetchRandomHadith() async {
    try {
      final hadith = await hadithService.fetchRandomHadith();
      _hadithDaily = hadith;
      _lastFetchedDate = DateTime.now();
      notifyListeners();
    } catch (e) {
      print("Error $e");
    }
  }

  void startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_times == null) return;

      final now = DateTime.now();

      final prayerMap = {
        "Fajr": _times!.fajr,
        "Dhuhr": _times!.dhuhr,
        "Asr": _times!.asr,
        "Maghrib": _times!.maghrib,
        "Isha": _times!.isha,
      };

      final prayerTimesList = prayerMap.entries.map((entry) {
        final parts = entry.value.split(":");
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return MapEntry(
          entry.key,
          DateTime(now.year, now.month, now.day, hour, minute),
        );
      }).toList();

      final nextPrayer = prayerTimesList.firstWhere(
        (entry) => entry.value.isAfter(now),
        orElse: () {
          final parts = prayerMap["Fajr"]!.split(":");
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          return MapEntry(
            "Fajr",
            DateTime(now.year, now.month, now.day + 1, hour, minute),
          );
        },
      );

      _nextPrayerText = nextPrayer.key;
      _nextPrayerDate = nextPrayer.value;

      final diff = nextPrayer.value.difference(now);
      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

      _countdownText = "$hours:$minutes:$seconds";

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  void checkIfShouldAskLocation() {
    if (times == null && !_isPrayerTimesLoading) {
      _shouldAskLocation = true;
      notifyListeners();
    }
  }

  void setLocationAsked() {
    _shouldAskLocation = false;
    notifyListeners();
  }
}
