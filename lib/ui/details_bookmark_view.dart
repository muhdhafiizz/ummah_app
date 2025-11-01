import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:ramadhan_companion_app/provider/bookmark_provider.dart';
import 'package:ramadhan_companion_app/ui/hadith_view.dart';
import 'package:ramadhan_companion_app/ui/quran_detail_view.dart';
import 'package:ramadhan_companion_app/ui/quran_page_view.dart';
import 'package:ramadhan_companion_app/widgets/app_colors.dart';
import 'package:ramadhan_companion_app/widgets/custom_button.dart';

class DetailsBookmarkView extends StatelessWidget {
  const DetailsBookmarkView({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final bookmarks = bookmarkProvider.bookmarks;
    final query = bookmarkProvider.query.toLowerCase();

    final verseBookmarks = bookmarks
        .where((b) => !b.startsWith("page:") && !b.startsWith("hadith:"))
        .toList();
    final pageBookmarks = bookmarks
        .where((b) => b.startsWith("page:"))
        .toList();
    final hadithBookmarks = bookmarks
        .where((b) => b.startsWith("hadith:"))
        .toList();

    // --- Filter ---
    List<String> filter(List<String> list) {
      if (query.isEmpty) return list;
      return list.where((b) => b.toLowerCase().contains(query)).toList();
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildAppBar(context),
              // const SizedBox(height: 10),
              // _buildSearchBar(context, bookmarkProvider),
              const SizedBox(height: 15),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        context,
                        "Qur'an Verses",
                        filter(verseBookmarks),
                      ),
                      const Divider(height: 30),
                      _buildSection(
                        context,
                        "Qur'an Pages",
                        filter(pageBookmarks),
                      ),
                      const Divider(height: 30),
                      _buildSection(
                        context,
                        "Hadiths",
                        filter(hadithBookmarks),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final provider = context.watch<BookmarkProvider>();
    final isEditing = provider.isEditing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.arrow_back),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bookmarks',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
            ),
            CustomButton(
              onTap: () => provider.toggleEditMode(),
              text: isEditing ? 'Done' : 'Edit',
              backgroundColor: Colors.white,
            ),
          ],
        ),
      ],
    );
  }

  // Widget _buildSearchBar(
  //   BuildContext context,
  //   BookmarkProvider filterProvider,
  // ) {
  //   return TextField(
  //     onChanged: filterProvider.updateQuery,
  //     decoration: InputDecoration(
  //       hintText: "Search bookmarks...",
  //       prefixIcon: const Icon(Icons.search),
  //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  //       filled: true,
  //       fillColor: Colors.grey.shade100,
  //     ),
  //   );
  // }

  Widget _buildSection(BuildContext context, String title, List<String> items) {
    final provider = context.watch<BookmarkProvider>();
    final isEditing = provider.isEditing;
    final violet = AppColors.violet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTitleText(title),
            if (isEditing && items.isNotEmpty)
              GestureDetector(
                onTap: () => _confirmDeleteCategory(context, title),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: violet, width: 1.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 18),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        items.isEmpty
            ? const Text(
                "No bookmarks found.",
                style: TextStyle(color: Colors.grey),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items
                    .map((b) => _buildBookmarkChip(context, b))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildTitleText(String name) {
    return Text(
      name,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
    );
  }

  Widget _buildBookmarkChip(BuildContext context, String bookmark) {
    final violet = AppColors.violet.withOpacity(1);
    final chipDecoration = BoxDecoration(
      color: Colors.white,
      border: Border.all(color: violet, width: 1.5),
      borderRadius: BorderRadius.circular(24),
    );

    String label;
    VoidCallback? onTap;

    if (bookmark.startsWith("page:")) {
      final page = int.tryParse(bookmark.split(":")[1]) ?? 0;
      label = "Page $page";
      onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuranPageView(pageNumber: page)),
        );
      };
    } else if (bookmark.startsWith("hadith:")) {
      final parts = bookmark.split(":");
      if (parts.length < 3) return const SizedBox.shrink();

      final bookSlug = parts[1];
      final hadithId = parts[2];

      label = "${bookSlug.replaceAll('-', ' ').toUpperCase()} #$hadithId";
      onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HadithView(bookSlug: bookSlug, chapterId: hadithId),
          ),
        );
      };
    } else {
      // ---- Verse Bookmark ----
      final parts = bookmark.split(":");
      if (parts.length != 2) return const SizedBox.shrink();
      final surah = int.tryParse(parts[0]) ?? 0;
      final verse = int.tryParse(parts[1]) ?? 0;
      final name = quran.getSurahName(surah);
      label = "$name : $verse";
      onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SurahDetailView(surahNumber: surah, initialVerse: verse),
          ),
        );
      };
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: chipDecoration,
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, String title) async {
    final provider = context.read<BookmarkProvider>();

    Future<void> confirmDelete() async {
      await provider.clearCategory(title);
    }

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text("Clear All $title"),
          content: Text(
            "Are you sure you want to delete all $title bookmarks?",
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text("Delete All"),
              onPressed: () async {
                Navigator.pop(context);
                await confirmDelete();
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Clear All $title"),
          content: Text(
            "Are you sure you want to delete all $title bookmarks?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await confirmDelete();
              },
              child: const Text(
                "Delete All",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }
  }
}
