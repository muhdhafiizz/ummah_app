import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:ramadhan_companion_app/helper/distance_calculation.dart';
import 'package:ramadhan_companion_app/provider/bookmark_provider.dart';
import 'package:ramadhan_companion_app/provider/quran_detail_provider.dart';
import 'package:ramadhan_companion_app/ui/quran_page_view.dart';
import 'package:ramadhan_companion_app/widgets/app_colors.dart';
import 'package:ramadhan_companion_app/widgets/custom_audio_snackbar.dart';
import 'package:ramadhan_companion_app/widgets/custom_pill_snackbar.dart';
import 'package:ramadhan_companion_app/widgets/custom_textfield.dart';
import 'package:ramadhan_companion_app/widgets/shimmer_loading.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';

class SurahDetailView extends StatelessWidget {
  final int surahNumber;
  final int? initialVerse;

  const SurahDetailView({
    super.key,
    required this.surahNumber,
    this.initialVerse,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          QuranDetailProvider(surahNumber, initialVerse: initialVerse),
      builder: (context, child) {
        return _SurahDetailBody(
          // surahNumber: surahNumber,
          initialVerse: initialVerse,
        );
      },
    );
  }
}

class _SurahDetailBody extends StatelessWidget {
  final int? initialVerse;

  const _SurahDetailBody({this.initialVerse});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuranDetailProvider>();
    final surahNumber = provider.surahNumber;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildAppBar(context, surahNumber),
              const SizedBox(height: 10),
              CustomTextField(
                label: "Search verse or verse number",
                onChanged: provider.search,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Stack(
                  children: [
                    ScrollablePositionedList.builder(
                      itemScrollController: provider.itemScrollController,
                      itemPositionsListener: provider.itemPositionsListener,
                      itemCount: (surahNumber != 1 && surahNumber != 9)
                          ? provider.verses.length + 1
                          : provider.verses.length,
                      itemBuilder: (context, index) {
                        if (index == 0 &&
                            surahNumber != 1 &&
                            surahNumber != 9) {
                          return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              quran.basmala,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'AmiriQuran',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 2.5,
                              ),
                            ),
                          );
                        }

                        final verseIndex =
                            (surahNumber != 1 && surahNumber != 9)
                            ? index - 1
                            : index;

                        final verse = provider.verses[verseIndex];
                        final verseNum = int.parse(verse["number"]!);
                        final expanded = provider.isExpanded(verseNum);
                        final tafsirText = provider.getTafsir(verseNum);

                        return Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                verse["arabic"]!,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontFamily: 'AmiriQuran',
                                  fontSize: provider.arabicFontSize,
                                  fontWeight: FontWeight.bold,
                                  height: 2.5,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                verse["translation"]!,
                                style: TextStyle(
                                  fontSize: provider.translationFontSize,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // === Actions row ===
                              Row(
                                children: [
                                  _buildBookmark(
                                    context,
                                    surahNumber,
                                    verseNum,
                                  ),
                                  const SizedBox(width: 5),
                                  _buildVerseAudio(
                                    provider,
                                    surahNumber,
                                    verseNum,
                                  ),
                                  const SizedBox(width: 5),
                                  _buildShareButton(
                                    context,
                                    verse,
                                    surahNumber,
                                    verseNum,
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () =>
                                        provider.toggleTafsir(verseNum),
                                    child: Row(
                                      children: [
                                        Icon(
                                          expanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: AppColors.violet.withOpacity(
                                            1,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          "Tafsir",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // === Tafsir content ===
                              if (expanded)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: tafsirText == null
                                      ? Center(child: _buildShimmerLoading())
                                      : Text(
                                          tafsirText,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                            height: 1.5,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                ),

                              const SizedBox(height: 5),
                              const Divider(),
                            ],
                          ),
                        );
                      },
                    ),

                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Column(
                        children: [
                          if (provider.showScrollUp)
                            FloatingActionButton(
                              shape: const CircleBorder(),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              mini: true,
                              heroTag: "scroll_up",
                              onPressed: provider.scrollToTop,
                              child: const Icon(Icons.arrow_upward),
                            ),
                          const SizedBox(height: 10),
                          if (provider.showScrollDown)
                            FloatingActionButton(
                              shape: const CircleBorder(),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              mini: true,
                              heroTag: "scroll_down",
                              onPressed: provider.scrollToBottom,
                              child: const Icon(Icons.arrow_downward),
                            ),
                        ],
                      ),
                    ),
                    Positioned(bottom: 20, right: 90, child: AudioPillWidget()),
                  ],
                ),
              ),
              _buildBottomNavForSurah(
                context,
                surahNumber: surahNumber,
                provider: provider,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildAppBar(BuildContext context, int surahNumber) {
  final surahNameArabic = quran.getSurahName(surahNumber);
  final surahNameEnglish = quran.getSurahNameEnglish(surahNumber);
  final provider = context.watch<QuranDetailProvider>();

  return Row(
    children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            surahNameArabic,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(surahNameEnglish, style: const TextStyle(fontSize: 14)),
        ],
      ),
      const Spacer(),
      GestureDetector(
        onTap: () => showQuranSettingsBottomSheet(context, provider),
        child: Icon(
          Icons.menu_outlined,
          color: AppColors.violet.withOpacity(1),
        ),
        // Image.asset(
        //   'assets/icon/slider_filled_icon.png',
        //   width: 24,
        //   height: 24,
        // ),
      ),

      SizedBox(width: 10),
      GestureDetector(
        onTap: () {
          provider.playAudio();
        },
        child: Icon(
          Icons.volume_up_outlined,
          color: AppColors.violet.withOpacity(1),
        ),
        // Image.asset(
        //   'assets/icon/volume_icon.png',
        //   width: 24,
        //   height: 24,
        // ),
      ),
    ],
  );
}

Widget _buildShimmerLoading() {
  return Column(
    children: [
      ShimmerLoadingWidget(height: 20, width: double.infinity),
      SizedBox(height: 5),
      ShimmerLoadingWidget(height: 20, width: double.infinity),
      SizedBox(height: 5),
      ShimmerLoadingWidget(height: 20, width: double.infinity),
    ],
  );
}

Widget _buildBottomNavForSurah(
  BuildContext context, {
  required int surahNumber,
  required QuranDetailProvider provider,
}) {
  final bool isFirstSurah = surahNumber == 1;
  final bool isLastSurah = surahNumber == 114;

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      border: Border(top: BorderSide(color: Colors.grey.shade300)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!isFirstSurah)
          ElevatedButton.icon(
            style: whiteButtonStyle,
            onPressed: () async {
              await provider.loadSurah(surahNumber - 1);
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            label: const Text("Previous"),
          )
        else
          const SizedBox(width: 120),

        GestureDetector(
          onTap: () => showSurahList(context, provider),
          child: Text(
            "Surah $surahNumber / 114",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              decoration: TextDecoration.underline,
            ),
          ),
        ),

        if (!isLastSurah)
          ElevatedButton.icon(
            style: blackButtonStyle,
            onPressed: () async {
              await provider.loadSurah(surahNumber + 1);
            },
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            label: const Text("Next"),
          )
        else
          const SizedBox(width: 120),
      ],
    ),
  );
}

Widget _buildBookmark(BuildContext context, int surahNumber, int verseNum) {
  final bookmarkProvider = Provider.of<BookmarkProvider>(context);

  return IconButton(
    icon: Image.asset(
      bookmarkProvider.isVerseBookmarked(surahNumber, verseNum)
          ? "assets/icon/bookmark_icon.png"
          : "assets/icon/bookmark_empty_icon.png",
      width: 20,
      height: 20,
    ),
    onPressed: () {
      bookmarkProvider.toggleVerseBookmark(surahNumber, verseNum);

      bookmarkProvider.isVerseBookmarked(surahNumber, verseNum)
          ? CustomPillSnackbar.show(
              context,
              message: "✅ Added to bookmark",
              backgroundColor: Colors.black,
            )
          : CustomPillSnackbar.show(
              context,
              message: "❌ Removed from bookmark",
              backgroundColor: Colors.black,
            );
    },
  );
}

Widget _buildShareButton(
  BuildContext context,
  Map<String, String> verse,
  int surahNumber,
  int verseNum,
) {
  return IconButton(
    icon: Image.asset(
      'assets/icon/share_outlined_icon_1.png',
      width: 20,
      height: 20,
    ),
    onPressed: () {
      final arabicClean = cleanArabic(
        quran.getVerse(surahNumber, verseNum, verseEndSymbol: false),
      );

      final textToShare =
          "$arabicClean\n\n${verse["translation"]}\n\n"
          "Surah $surahNumber : Ayah $verseNum";

      Share.share(textToShare);
    },
  );
}

Widget _buildVerseAudio(
  QuranDetailProvider provider,
  int surahNumber,
  int verseNumber,
) {
  final isPlayingThisVerse =
      provider.playingVerse == verseNumber && provider.isVersePlaying;

  return GestureDetector(
    onTap: () {
      if (isPlayingThisVerse) {
        provider.pauseVerseAudio();
      } else {
        provider.playAudioVerse(verse: verseNumber);
      }
    },
    child: Image.asset(
      isPlayingThisVerse
          ? 'assets/icon/volume_icon.png'
          : 'assets/icon/volume_outlined_icon.png',
      height: 24,
      width: 24,
    ),
  );
}

Future<void> showQuranSettingsBottomSheet(
  BuildContext context,
  QuranDetailProvider provider,
) async {
  return showModalBottomSheet(
    backgroundColor: Colors.white,
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return ChangeNotifierProvider.value(
        value: provider,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text(
                "Adjust Quran Settings",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Translation Language Selector
              const Text(
                "Translation Language",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Consumer<QuranDetailProvider>(
                builder: (_, provider, __) {
                  final selectedLang = provider.availableTranslations
                      .firstWhere(
                        (lang) => lang["value"] == provider.selectedTranslation,
                        orElse: () => provider.availableTranslations.first,
                      );

                  return InkWell(
                    onTap: () => _showTranslationSelector(provider, context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(selectedLang["name"]),
                          const Icon(Icons.keyboard_arrow_down_rounded),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),

              // Arabic Font Size
              const Text(
                "Arabic Font Size",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Consumer<QuranDetailProvider>(
                builder: (_, provider, __) {
                  return Slider(
                    value: provider.arabicFontSize,
                    min: 18,
                    max: 40,
                    divisions: 4,
                    activeColor: Colors.black,
                    inactiveColor: Colors.grey.shade300,
                    label: "${provider.arabicFontSize.toInt()}",
                    onChanged: provider.setArabicFontSize,
                  );
                },
              ),

              const SizedBox(height: 15),

              // Translation Font Size
              const Text(
                "Translation Font Size",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Consumer<QuranDetailProvider>(
                builder: (_, provider, __) {
                  return Slider(
                    value: provider.translationFontSize,
                    min: 12,
                    max: 30,
                    divisions: 4,
                    activeColor: Colors.black,
                    inactiveColor: Colors.grey.shade300,
                    label: "${provider.translationFontSize.toInt()}",
                    onChanged: provider.setTranslationFontSize,
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Bottom sheet for translation selection
void _showTranslationSelector(
  QuranDetailProvider provider,
  BuildContext context,
) {
  showModalBottomSheet(
    backgroundColor: Colors.white,
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Text(
              "Select Translation",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...provider.availableTranslations.map((lang) {
              final isSelected = lang["value"] == provider.selectedTranslation;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  lang["name"],
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.grey.shade700,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  provider.setTranslationLanguage(lang["value"]);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      );
    },
  );
}

void showSurahList(BuildContext context, QuranDetailProvider provider) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      final TextEditingController searchController = TextEditingController();
      final ValueNotifier<String> searchQuery = ValueNotifier('');

      final double sheetHeight = MediaQuery.of(context).size.height * 0.75;

      return SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const Text(
                  "Select Surah",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                // 🔍 Search bar
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search Surah name or number...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => searchQuery.value = value,
                ),
                const SizedBox(height: 15),

                // 📜 Surah list
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: searchQuery,
                    builder: (_, query, __) {
                      final surahs = List.generate(114, (i) => i + 1).where((
                        num,
                      ) {
                        final arabic = quran.getSurahName(num);
                        final english = quran.getSurahNameEnglish(num);
                        return arabic.contains(query) ||
                            english.toLowerCase().contains(
                              query.toLowerCase(),
                            ) ||
                            num.toString() == query;
                      }).toList();

                      return ListView.builder(
                        itemCount: surahs.length,
                        itemBuilder: (context, index) {
                          final num = surahs[index];
                          final arabic = quran.getSurahName(num);
                          final english = quran.getSurahNameEnglish(num);
                          final ayahCount = quran.getVerseCount(num);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              child: Text(
                                num.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              arabic,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text("$english • $ayahCount verses"),
                            onTap: () async {
                              Navigator.pop(context);
                              await provider.loadSurah(num);
                            },
                          );
                        },
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
