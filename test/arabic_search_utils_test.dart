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
  });
}
