import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_audio_catalog.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_curriculum_catalog.dart';
import 'package:talib_ilm/features/ilm/data/models/mutun_models.dart';
import 'package:talib_ilm/features/ilm/data/services/mutun_audio_service.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/mutn_curriculum_reader_view.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/mutn_quick_jump_sheet.dart';

void main() {
  group('MutunCurriculumCatalog Tests', () {
    test('bk_adhkar_adab matches authentic 24 paragraphs recited by Dr. As-Sini', () {
      expect(MutunCurriculumCatalog.hasBook('bk_adhkar_adab'), isTrue);
      final book = MutunCurriculumCatalog.getBook('bk_adhkar_adab')!;

      expect(book.title, 'الأذكار والآداب');
      expect(book.totalParagraphs, 24);
      expect(book.sections.length, 9);

      final p1 = book.getParagraph(1);
      expect(p1, isNotNull);
      expect(p1!.text, contains('مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا'));

      final p24 = book.getParagraph(24);
      expect(p24, isNotNull);
      expect(p24!.text, contains('غُفْرَانَكَ'));

      // Check audio catalog consistency
      final audioEntry = MutunAudioCatalog.getEntry('bk_adhkar_adab');
      expect(audioEntry, isNotNull);
      expect(audioEntry!.totalParagraphs, book.totalParagraphs);
    });

    test('bk_nawaqid_islam matches 10 paragraphs recited by Dr. As-Sini', () {
      expect(MutunCurriculumCatalog.hasBook('bk_nawaqid_islam'), isTrue);
      final book = MutunCurriculumCatalog.getBook('bk_nawaqid_islam')!;

      expect(book.totalParagraphs, 10);
      expect(book.sections.length, 10);

      final audioEntry = MutunAudioCatalog.getEntry('bk_nawaqid_islam');
      expect(audioEntry, isNotNull);
      expect(audioEntry!.totalParagraphs, book.totalParagraphs);
    });

    test('bk_qawaid_arba matches 8 paragraphs recited by Dr. As-Sini', () {
      expect(MutunCurriculumCatalog.hasBook('bk_qawaid_arba'), isTrue);
      final book = MutunCurriculumCatalog.getBook('bk_qawaid_arba')!;

      expect(book.totalParagraphs, 8);
      expect(book.getParagraph(1)!.text, contains('عُنْوَانُ السَّعَادَةِ'));

      final audioEntry = MutunAudioCatalog.getEntry('bk_qawaid_arba');
      expect(audioEntry, isNotNull);
      expect(audioEntry!.totalParagraphs, book.totalParagraphs);
    });

    test('bk_usul_thalatha matches 28 paragraphs recited by Dr. As-Sini', () {
      expect(MutunCurriculumCatalog.hasBook('bk_usul_thalatha'), isTrue);
      final book = MutunCurriculumCatalog.getBook('bk_usul_thalatha')!;

      expect(book.totalParagraphs, 28);
      expect(book.getParagraph(1)!.text, contains('تَعَلُّمُ أَرْبَعِ مَسَائِلَ'));
      expect(book.getParagraph(28)!.text, contains('أَعْظَمُ الطَّوَاغِيتِ خَمْسَةٌ'));

      final audioEntry = MutunAudioCatalog.getEntry('bk_usul_thalatha');
      expect(audioEntry, isNotNull);
      expect(audioEntry!.totalParagraphs, book.totalParagraphs);
    });

    test('bk_shuroot_salah matches 14 paragraphs recited by Dr. As-Sini', () {
      expect(MutunCurriculumCatalog.hasBook('bk_shuroot_salah'), isTrue);
      final book = MutunCurriculumCatalog.getBook('bk_shuroot_salah')!;

      expect(book.totalParagraphs, 14);
      expect(book.getParagraph(1)!.text, contains('شُرُوطُ الصَّلَاةِ تِسْعَةٌ'));

      final audioEntry = MutunAudioCatalog.getEntry('bk_shuroot_salah');
      expect(audioEntry, isNotNull);
      expect(audioEntry!.totalParagraphs, book.totalParagraphs);
    });

    test('bk_tuhfat_atfal matches 61 verses recited by Dr. As-Sini', () {
      expect(MutunCurriculumCatalog.hasBook('bk_tuhfat_atfal'), isTrue);
      final book = MutunCurriculumCatalog.getBook('bk_tuhfat_atfal')!;

      expect(book.totalParagraphs, 61);
      expect(book.getParagraph(1)!.text, contains('يَقُولُ رَاجِي رَحْمَةِ الْغَفُورِ'));
      expect(book.getParagraph(61)!.text, contains('وَكُلِّ قَارِئٍ وَكُلِّ سَامِعِ'));

      final audioEntry = MutunAudioCatalog.getEntry('bk_tuhfat_atfal');
      expect(audioEntry, isNotNull);
      expect(audioEntry!.totalParagraphs, book.totalParagraphs);
    });
  });

  group('MutnCurriculumReaderView Widget Tests', () {
    testWidgets('renders sections, paragraph badges, and quick jump pill', (tester) async {
      final curriculumBook = MutunCurriculumCatalog.getBook('bk_adhkar_adab')!;
      final ilmBook = IlmBook(
        id: 'bk_adhkar_adab',
        title: 'الآداب والأذكار',
        author: 'د. عبد المحسن بن محمد القاسم',
        level: 'المستوى التمهيدي',
        subject: 'الآداب والأذكار',
        description: 'متن الآداب والأذكار',
        totalPages: 24,
        shuruh: const [],
      );

      final audioService = MutunAudioService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MutnCurriculumReaderView(
              book: ilmBook,
              curriculumBook: curriculumBook,
              audioService: audioService,
              onAddNote: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Section headers exist
      expect(find.text('فضل طلب العلم'), findsOneWidget);

      // Verify Paragraph badges exist
      expect(find.text('- 1 -'), findsOneWidget);
      expect(find.text('- 2 -'), findsOneWidget);

      // Verify tap on paragraph seeks audio
      await tester.tap(find.text('- 2 -'));
      await tester.pump();
      expect(audioService.activeParagraphNotifier.value, 2);
      audioService.dispose();
    });

    testWidgets('MutunQuickJumpSheet lists all sections and handles selection', (tester) async {
      final curriculumBook = MutunCurriculumCatalog.getBook('bk_adhkar_adab')!;
      int? selectedPara;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MutunQuickJumpSheet(
              sections: curriculumBook.sections,
              activeParagraph: 1,
              onParagraphSelected: (para) {
                selectedPara = para;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('الانتقال السريع بين أبواب وفصول المتن'), findsOneWidget);
      expect(find.text('فضل طلب العلم'), findsOneWidget);
      expect(find.text('فضل تعلم القرآن'), findsOneWidget);

      // Tap on second section
      await tester.tap(find.text('فضل تعلم القرآن'));
      await tester.pumpAndSettle();

      expect(selectedPara, 4); // First paragraph of section 2 is 4
    });
  });
}
