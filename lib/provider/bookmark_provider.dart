import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkProvider extends ChangeNotifier {
  // Use Set for faster lookup & value-based equality
  Set<String> _bookmarks = {};
  String _query = '';
  bool _isEditing = false;

  // Public getters
  List<String> get bookmarks => _bookmarks.toList();
  String get query => _query;
  bool get isEditing => _isEditing;

  BookmarkProvider() {
    _loadBookmarks();
  }

  // 🧩 Load bookmarks from SharedPreferences
  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList("bookmarks") ?? [];

    _bookmarks = stored.where(_isValidBookmark).map((b) => b.trim()).toSet();

    // Resave cleaned bookmarks if necessary
    await _save();
    notifyListeners();
  }

  // 🧠 Toggle a hadith bookmark
  Future<void> toggleHadithBookmark(
    String bookSlug,
    String chapterId,
    String hadithId,
  ) async {
    final key =
        "hadith:${bookSlug.trim()}:${chapterId.trim()}:${hadithId.trim()}";

    if (_bookmarks.contains(key)) {
      print('REMOVE BOOKMARK → $key');
      _bookmarks.remove(key);
    } else {
      print('ADD BOOKMARK → $key');
      _bookmarks.add(key);
    }

    print('ALL BOOKMARKS → $_bookmarks');
    await _save();
    notifyListeners();
  }

  // 🧠 Toggle a Quran page bookmark
  Future<void> togglePageBookmark(int pageNumber) async {
    final key = "page:$pageNumber";
    if (_bookmarks.contains(key)) {
      _bookmarks.remove(key);
    } else {
      _bookmarks.add(key);
    }
    await _save();
    notifyListeners();
  }

  // 🧠 Toggle a verse bookmark
  Future<void> toggleVerseBookmark(int surahNumber, int verseNumber) async {
    final key = "$surahNumber:$verseNumber";
    if (_bookmarks.contains(key)) {
      _bookmarks.remove(key);
    } else {
      _bookmarks.add(key);
    }
    await _save();
    notifyListeners();
  }

  // ✅ Check if hadith is bookmarked
  bool isHadithBookmarked(String bookSlug, String chapterId, String hadithId) {
    final key =
        "hadith:${bookSlug.trim()}:${chapterId.trim()}:${hadithId.trim()}";
    print('isHadithBookmarked: $key');
    final exists = _bookmarks.contains(key);
    print('EXISTS? $exists');
    return exists;
  }

  // ✅ Check if a page is bookmarked
  bool isPageBookmarked(int pageNumber) =>
      _bookmarks.contains("page:$pageNumber");

  // ✅ Check if a verse is bookmarked
  bool isVerseBookmarked(int surahNumber, int verseNumber) =>
      _bookmarks.contains("$surahNumber:$verseNumber");

  // 🧹 Validate stored bookmark formats
  bool _isValidBookmark(String bookmark) {
    if (bookmark.startsWith("page:")) {
      final page = int.tryParse(bookmark.split(":")[1]);
      return page != null && page > 0;
    }

    if (bookmark.startsWith("hadith:")) {
      final parts = bookmark.split(":");
      // Example: hadith:sahih-bukhari:1:1
      return parts.length >= 4 &&
          parts[1].isNotEmpty &&
          parts[2].isNotEmpty &&
          parts[3].isNotEmpty;
    }

    final parts = bookmark.split(":");
    if (parts.length != 2) return false;

    final surah = int.tryParse(parts[0]);
    final verse = int.tryParse(parts[1]);
    return surah != null && verse != null && surah > 0 && verse > 0;
  }

  // 💾 Persist all bookmarks to SharedPreferences
  Future<void> _save() async {
    _bookmarks = _bookmarks.where(_isValidBookmark).toSet();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("bookmarks", _bookmarks.toList());
  }

  // 🔍 Search-related
  void updateQuery(String value) {
    _query = value;
    notifyListeners();
  }

  // ✏️ Edit mode toggle
  void toggleEditMode() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  // ❌ Remove a specific bookmark
  Future<void> removeBookmark(String bookmark) async {
    _bookmarks.remove(bookmark);
    await _save();
    notifyListeners();
  }

  Future<void> clearCategory(String category) async {
    print('clearCategory $category');
    if (category == "Qur'an Verses") {
      print('Verses');

      _bookmarks.removeWhere(
        (b) => !b.startsWith("page:") && !b.startsWith("hadith:"),
      );
    } else if (category == "Qur'an Pages") {
      print('quran');

      _bookmarks.removeWhere((b) => b.startsWith("page:"));
    } else if (category == "Hadiths") {
      print('Hadith');

      _bookmarks.removeWhere((b) => b.startsWith("hadith:"));
    } else if (category == "All") {
      _bookmarks.clear();
    }

    await _save();
    notifyListeners();
  }
}
