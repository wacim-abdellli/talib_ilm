import 'dart:convert';
import 'package:flutter/services.dart';
import 'adhkar_models.dart';
import '../../../app/constants/app_assets.dart';
import '../../../app/constants/app_strings.dart';

class AthkarService {
  Future<AthkarCatalog>? _cache;

  Future<AthkarCatalog> loadCatalog() {
    final cached = _cache;
    if (cached != null) {
      return cached.catchError((error) {
        _cache = null;
        return _fallbackCatalog();
      });
    }
    _cache = _loadFromAssets();
    return _cache!.catchError((error) {
      _cache = null;
      return _fallbackCatalog();
    });
  }

  Future<AthkarCatalog> _loadFromAssets() async {
    final raw = await rootBundle.loadString(AppAssets.adhkarData);
    final decoded = jsonDecode(raw);
    List<AthkarCategoryData> categories;

    if (decoded is Map<String, dynamic>) {
      final rawCategories = decoded['categories'] as List? ?? [];
      categories = rawCategories
          .whereType<Map<String, dynamic>>()
          .map(AthkarCategoryData.fromJson)
          .toList();
    } else if (decoded is List) {
      final items = decoded
          .whereType<Map<String, dynamic>>()
          .map(AthkarItem.fromJson)
          .toList();
      categories = _categoriesFromItems(items);
    } else {
      categories = const [];
    }

    final merged = List<AthkarCategoryData>.from(categories);
    final fallback = _fallbackCatalog().categories;
    final existingIds = merged.map((c) => c.id).toSet();
    for (final category in fallback) {
      if (!existingIds.contains(category.id)) {
        merged.add(category);
      }
    }
    return AthkarCatalog(categories: merged);
  }

  void resetCache() {
    _cache = null;
  }

  List<AthkarCategoryData> _categoriesFromItems(List<AthkarItem> items) {
    if (items.isEmpty) return [];

    final hasOrder = items.every((item) => item.order > 0);
    if (hasOrder) {
      items.sort((a, b) => a.order.compareTo(b.order));
    }

    final morningItems = <AthkarItem>[];
    final eveningItems = <AthkarItem>[];

    for (final item in items) {
      if (item.type == 1) {
        morningItems.add(item);
      } else if (item.type == 2) {
        eveningItems.add(item);
      } else {
        morningItems.add(item);
        eveningItems.add(item);
      }
    }

    return [
      AthkarCategoryData(
        id: 'morning',
        title: AppStrings.adhkarMorning,
        subtitle: AppStrings.adhkarMorningSubtitle,
        items: morningItems,
      ),
      AthkarCategoryData(
        id: 'evening',
        title: AppStrings.adhkarEvening,
        subtitle: AppStrings.adhkarEveningSubtitle,
        items: eveningItems,
      ),
    ];
  }

  AthkarCatalog _fallbackCatalog() {
    return AthkarCatalog(
      categories: [
        AthkarCategoryData(
          id: 'morning',
          title: AppStrings.adhkarMorning,
          subtitle: AppStrings.adhkarMorningSubtitle,
          items: [
            _fallbackItem(
              id: 'morning_1',
              arabic: 'أصبحنا وأصبح الملك لله والحمد لله',
              transliteration: 'Asbahna wa asbaha al-mulku lillah',
              meaning: 'We have entered the morning and the dominion belongs to Allah',
              target: 1,
            ),
            _fallbackItem(
              id: 'morning_2',
              arabic: 'سبحان الله وبحمده',
              transliteration: 'Subhan Allah wa bi hamdih',
              meaning: 'Glory be to Allah and praise be to Him',
              target: 100,
            ),
            _fallbackItem(
              id: 'morning_3',
              arabic: 'رضيت بالله ربًا وبالإسلام دينًا',
              transliteration: 'Raditu billahi rabban wa bil-islami dinan',
              meaning: 'I am pleased with Allah as Lord and Islam as religion',
              target: 3,
            ),
          ],
        ),
        AthkarCategoryData(
          id: 'evening',
          title: AppStrings.adhkarEvening,
          subtitle: AppStrings.adhkarEveningSubtitle,
          items: [
            _fallbackItem(
              id: 'evening_1',
              arabic: 'أمسينا وأمسى الملك لله والحمد لله',
              transliteration: 'Amsayna wa amsa al-mulku lillah',
              meaning: 'We have entered the evening and the dominion belongs to Allah',
              target: 1,
            ),
            _fallbackItem(
              id: 'evening_2',
              arabic: 'سبحان الله وبحمده',
              transliteration: 'Subhan Allah wa bi hamdih',
              meaning: 'Glory be to Allah and praise be to Him',
              target: 100,
            ),
            _fallbackItem(
              id: 'evening_3',
              arabic: 'حسبي الله لا إله إلا هو',
              transliteration: 'Hasbi Allahu la ilaha illa Huwa',
              meaning: 'Allah is sufficient for me; there is no deity but Him',
              target: 7,
            ),
          ],
        ),
        AthkarCategoryData(
          id: 'after_prayer',
          title: AppStrings.adhkarAfterPrayer,
          subtitle: AppStrings.adhkarAfterPrayerSubtitle,
          items: [
            _fallbackItem(
              id: 'after_1',
              arabic: 'أستغفر الله',
              transliteration: 'Astaghfirullah',
              meaning: "I seek Allah's forgiveness",
              target: 3,
            ),
            _fallbackItem(
              id: 'after_2',
              arabic: 'سبحان الله',
              transliteration: 'Subhan Allah',
              meaning: 'Glory be to Allah',
              target: 33,
            ),
            _fallbackItem(
              id: 'after_3',
              arabic: 'الحمد لله',
              transliteration: 'Alhamdulillah',
              meaning: 'All praise is for Allah',
              target: 33,
            ),
            _fallbackItem(
              id: 'after_4',
              arabic: 'الله أكبر',
              transliteration: 'Allahu Akbar',
              meaning: 'Allah is the Greatest',
              target: 34,
            ),
          ],
        ),
        AthkarCategoryData(
          id: 'tasbeeh',
          title: AppStrings.tasbeehTab,
          subtitle: AppStrings.adhkarFreeCountSubtitle,
          items: [
            _fallbackItem(
              id: 'tasbeeh_1',
              arabic: 'سبحان الله',
              transliteration: 'Subhan Allah',
              meaning: 'Glory be to Allah',
              target: 0,
            ),
            _fallbackItem(
              id: 'tasbeeh_2',
              arabic: 'الحمد لله',
              transliteration: 'Alhamdulillah',
              meaning: 'All praise is for Allah',
              target: 0,
            ),
            _fallbackItem(
              id: 'tasbeeh_3',
              arabic: 'الله أكبر',
              transliteration: 'Allahu Akbar',
              meaning: 'Allah is the Greatest',
              target: 0,
            ),
          ],
        ),
        AthkarCategoryData(
          id: 'istighfar',
          title: AppStrings.istighfarTab,
          subtitle: AppStrings.adhkarFreeCountSubtitle,
          items: [
            _fallbackItem(
              id: 'istighfar_1',
              arabic: 'أستغفر الله',
              transliteration: 'Astaghfirullah',
              meaning: "I seek Allah's forgiveness",
              target: 0,
            ),
            _fallbackItem(
              id: 'istighfar_2',
              arabic: 'رب اغفر لي وتب علي',
              transliteration: "Rabbi ighfir li wa tub 'alayya",
              meaning: 'My Lord, forgive me and accept my repentance',
              target: 0,
            ),
          ],
        ),
        AthkarCategoryData(
          id: 'duas',
          title: AppStrings.duasTitle,
          subtitle: AppStrings.adhkarDuasSubtitle,
          items: [
            _fallbackItem(
              id: 'dua_1',
              arabic: 'اللهم أعني على ذكرك وشكرك وحسن عبادتك',
              transliteration: "Allahumma a'inni 'ala dhikrika wa shukrika wa husni 'ibadatik",
              meaning: 'O Allah, help me to remember You, thank You, and worship You well',
              target: 1,
            ),
            _fallbackItem(
              id: 'dua_2',
              arabic: 'رب اغفر لي ولوالدي',
              transliteration: 'Rabbi ighfir li wa li walidayya',
              meaning: 'My Lord, forgive me and my parents',
              target: 1,
            ),
            _fallbackItem(
              id: 'dua_3',
              arabic: 'اللهم إني أسألك الهدى والتقى والعفاف والغنى',
              transliteration: "Allahumma inni as'aluka al-huda wa al-tuqa wa al-'afafa wa al-ghina",
              meaning: 'O Allah, I ask You for guidance, piety, chastity, and self-sufficiency',
              target: 1,
            ),
          ],
        ),
      ],
    );
  }

  AthkarItem _fallbackItem({
    required String id,
    required String arabic,
    required String transliteration,
    required String meaning,
    required int target,
  }) {
    return AthkarItem(
      id: id,
      arabic: arabic,
      transliteration: transliteration,
      meaning: meaning,
      target: target,
      countDescription: '',
      fadl: '',
      source: '',
      audio: '',
      hadithText: '',
      hadithExplanation: '',
      order: 0,
      type: 0,
    );
  }
}
