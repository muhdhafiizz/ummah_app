import 'package:flutter/material.dart';
import 'package:ramadhan_companion_app/model/doa_zikir_model.dart';
import 'package:ramadhan_companion_app/service/doa_zikir_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoaProvider with ChangeNotifier {
  final DoaService _doaService = DoaService();

  List<DoaModel> _doaList = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedSource = "all";

  List<DoaModel> get doaList => _doaList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedSource => _selectedSource;

  final List<String> _sources = [
    "all",
    "quran",
    "hadits",
    "pilihan",
    "harian",
    "ibadah",
    "haji",
    "lainnya",
  ];

  List<String> get sources => _sources;

  Future<void> getAllDoa({bool refresh = false}) async {
    _setLoading(true);
    try {
      _doaList = await _doaService.fetchAllDoa(useCache: !refresh);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getDoaBySource(String source, {bool refresh = false}) async {
    _setLoading(true);
    try {
      _doaList = await _doaService.fetchDoaBySource(source, useCache: !refresh);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Handle chip selection and trigger fetch
  Future<void> selectSource(String source) async {
    _selectedSource = source;
    notifyListeners();

    if (source == "all") {
      await getAllDoa();
    } else {
      await getDoaBySource(source);
    }
  }

  /// Optional: clear all cached data
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_all_doa');

    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith('cached_doa_source_'))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
