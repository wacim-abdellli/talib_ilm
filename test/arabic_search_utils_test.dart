import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/core/utils/arabic_search_utils.dart';

void main() {
  group('ArabicSearchUtils Tests', () {
    test('normalizes tashkeel / harakat', () {
      expect(
        ArabicSearchUtils.normalize('سُورَةُ الْبَقَرَةِ'),
        'سوره البقره',
      );
    });

    test('unifies alef variants (أ إ آ ٱ)', () {
      expect(
        ArabicSearchUtils.normalize('آل عِمْرَانَ'),
        ArabicSearchUtils.normalize('ال عمران'),
      );
      expect(
        ArabicSearchUtils.normalize('إِبْرَاهِيم'),
        ArabicSearchUtils.normalize('ابراهيم'),
      );
    });

    test('unifies taa marbuta and haa (ة vs ه)', () {
      expect(
        ArabicSearchUtils.normalize('البقرة'),
        ArabicSearchUtils.normalize('البقره'),
      );
    });

    test('matches queries with different spellings', () {
      expect(
        ArabicSearchUtils.matches('سُورَةُ الْبَقَرَةِ', 'البقره'),
        isTrue,
      );
      expect(
        ArabicSearchUtils.matches('سُورَةُ آلِ عِمْرَانَ', 'ال عمران'),
        isTrue,
      );
      expect(
        ArabicSearchUtils.matches('سُورَةُ يُوسُفَ', 'يوسف'),
        isTrue,
      );
      expect(
        ArabicSearchUtils.matches('سُورَةُ يس', 'يس'),
        isTrue,
      );
      expect(
        ArabicSearchUtils.matches('سُورَةُ الْكَهْفِ', 'الكهف'),
        isTrue,
      );
    });

    test('handles empty or blank queries gracefully', () {
      expect(ArabicSearchUtils.matches('سورة البقرة', ''), isTrue);
      expect(ArabicSearchUtils.normalize(''), '');
    });

    test('normalizes Eastern Arabic and Persian numerals to standard digits', () {
      expect(ArabicSearchUtils.normalize('١٠٠'), '100');
      expect(ArabicSearchUtils.normalize('سنة ١٤٤٥ هـ'), 'سنه 1445 ه');
      expect(ArabicSearchUtils.normalize('جلد ۲ صفحه ۳'), 'جلد 2 صفحه 3');
    });

    test('matches queries with Eastern or Western numerals interchangeably', () {
      expect(
        ArabicSearchUtils.matches('100 من عظماء الإسلام', '١٠٠'),
        isTrue,
      );
      expect(
        ArabicSearchUtils.matches('١٠٠ من عظماء الإسلام', '100'),
        isTrue,
      );
    });

    test('matches space-insensitive queries such as attached numbers and words', () {
      expect(
        ArabicSearchUtils.matches(
          'مائة من عظماء أمة الإسلام غيروا مجرى التاريخ (100 من عظماء الإسلام)',
          '100من عظماء الاسلام',
        ),
        isTrue,
      );
      expect(
        ArabicSearchUtils.matches(
          'الفقه الميسر في ضوء الكتاب والسنة',
          'الفقه الميسر',
        ),
        isTrue,
      );
      expect(
        ArabicSearchUtils.matches(
          'أصول الإيمان في ضوء الكتاب والسنة',
          'اصول الايمان',
        ),
        isTrue,
      );
      expect(
        ArabicSearchUtils.matches(
          'فضائل الصحابة للإمام أحمد بن حنبل',
          'فضائل الصحابة',
        ),
        isTrue,
      );
      expect(
        ArabicSearchUtils.matches(
          'منهاج المسلم (كتاب عقائد وآداب وأخلاق وعبادات ومعاملات)',
          'منهاج المسلم',
        ),
        isTrue,
      );
    });
  });
}
