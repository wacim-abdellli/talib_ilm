import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/ilm/data/models/book_progress_model.dart';
import 'package:talib_ilm/features/ilm/data/services/book_progress_service.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/islamic_quiz_catalog.dart';
import 'package:talib_ilm/features/ilm/data/services/quiz_progress_service.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/ilm_discipline_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ilm Real-time Book Progress & Session Resume Tests', () {
    late SharedPreferences prefs;
    late BookProgressService bookService;
    late QuizProgressService quizService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      bookService = BookProgressService(prefs);
      quizService = QuizProgressService(prefs);
    });

    test('BookProgressService returns page 1 reading progress in real time', () async {
      final now = DateTime.now();
      // User starts reading a book on page 1
      await bookService.saveBookProgress(
        BookProgress(
          bookId: 'bk_usul_thalatha',
          currentPage: 1,
          totalPages: 46,
          bookTitle: 'الأصول الثلاثة وأدلتها',
          level: 'المستوى الأول',
          startedDate: now,
          lastReadDate: now,
        ),
      );

      final currentlyReading = await bookService.getCurrentlyReading();
      expect(currentlyReading.isNotEmpty, isTrue);
      expect(currentlyReading.first.bookId, equals('bk_usul_thalatha'));
      expect(currentlyReading.first.currentPage, equals(1));

      final lastRead = await bookService.getLastReadBook();
      expect(lastRead, isNotNull);
      expect(lastRead!.bookId, equals('bk_usul_thalatha'));
    });

    test('BookProgressService accurately tracks latest read book across multiple books', () async {
      final earlierDate = DateTime.now().subtract(const Duration(hours: 2));
      final laterDate = DateTime.now();

      await bookService.saveBookProgress(
        BookProgress(
          bookId: 'bk_qawaid_arbaa',
          currentPage: 3,
          totalPages: 4,
          startedDate: earlierDate,
          lastReadDate: earlierDate,
          bookTitle: 'القواعد الأربع',
          level: 'المستوى الأول',
        ),
      );

      await bookService.saveBookProgress(
        BookProgress(
          bookId: 'shamela_123',
          currentPage: 15,
          totalPages: 100,
          startedDate: earlierDate,
          lastReadDate: laterDate,
          bookTitle: 'كتاب التوحيد',
          level: 'العقيدة',
        ),
      );

      final latest = await bookService.getLastReadBook();
      expect(latest, isNotNull);
      expect(latest!.bookId, equals('shamela_123'));
      expect(latest.currentPage, equals(15));
    });

    test('QuizProgressService saves and restores active quiz session smoothly', () async {
      const sessionId = 'fan_aqidah_level_1';

      // Verify initially no active session
      var active = quizService.getActiveSession(sessionId);
      expect(active, isNull);

      // Save ongoing progress at question 3
      final session = QuizActiveSession(
        currentIndex: 3,
        correctAnswers: 2,
        currentStreak: 2,
        maxStreak: 2,
        userAnswers: const [0, 1, 3],
      );

      await quizService.saveActiveSession(sessionId, session);

      // Restore session
      active = quizService.getActiveSession(sessionId);
      expect(active, isNotNull);
      expect(active!.currentIndex, equals(3));
      expect(active.correctAnswers, equals(2));
      expect(active.currentStreak, equals(2));
      expect(active.maxStreak, equals(2));
      expect(active.userAnswers, equals(const [0, 1, 3]));

      // Clear session after completing test
      await quizService.clearActiveSession(sessionId);
      expect(quizService.getActiveSession(sessionId), isNull);
    });

    test('IlmDisciplineSection provides rich authentic disciplines with quiz launchers', () {
      final disciplines = IlmDisciplineSection.disciplines;
      expect(disciplines.isNotEmpty, isTrue);

      // Verify Aqeedah, Hadith, Fiqh, Adab, Tafsir, Seerah, Arabic
      final keys = disciplines.map((d) => d.key).toList();
      expect(keys, containsAll(['aqidah', 'hadith', 'fiqh', 'adab', 'tafsir', 'seerah', 'arabic']));

      // Verify each discipline has books
      for (final d in disciplines) {
        expect(d.books.isNotEmpty, isTrue, reason: '${d.key} should have books');
        expect(d.title.isNotEmpty, isTrue);
      }

      // Verify disciplines with quizzes have a valid fan
      final aqidah = disciplines.firstWhere((d) => d.key == 'aqidah');
      expect(aqidah.fan, isNotNull);
      expect(aqidah.fan!.id, equals('aqidah'));

      final arabic = disciplines.firstWhere((d) => d.key == 'arabic');
      expect(arabic.fan, isNotNull);
      expect(arabic.fan!.id, equals('arabic'));
    });

    test('IslamicQuizCatalog has 240 authentic questions across 8 disciplines', () {
      final founoun = IslamicQuizCatalog.founoun;
      expect(founoun.length, equals(8));

      expect(IslamicQuizCatalog.totalQuestionsCount, equals(240));
      expect(IslamicQuizCatalog.totalLevelsCount, equals(24));

      for (final fan in founoun) {
        expect(fan.levels.length, equals(3), reason: '${fan.id} should have 3 levels');
        for (final level in fan.levels) {
          expect(level.questions.length, equals(10), reason: '${level.id} should have 10 questions');
          for (final q in level.questions) {
            expect(q.options.length, equals(4), reason: '${q.id} should have 4 options');
            expect(q.correctIndex, inInclusiveRange(0, 3), reason: '${q.id} correctIndex must be 0-3');
            expect(q.question.trim().isNotEmpty, isTrue, reason: '${q.id} question text must not be empty');
            expect(q.lesson.trim().isNotEmpty, isTrue, reason: '${q.id} lesson text must not be empty');
            expect(q.evidence.trim().isNotEmpty, isTrue, reason: '${q.id} evidence text must not be empty');
            expect(q.reference.trim().isNotEmpty, isTrue, reason: '${q.id} reference text must not be empty');
          }
        }
      }

      final daily = IslamicQuizCatalog.getDailyChallengeQuestions(count: 10);
      expect(daily.length, equals(10));
    });
  });
}
