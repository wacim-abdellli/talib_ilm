// ignore_for_file: avoid_print
import 'package:talib_ilm/features/ilm/data/catalogs/turath_catalog.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_digital_catalog.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_curriculum_catalog.dart';
import 'package:talib_ilm/features/ilm/data/models/shamela_models.dart';

void main() {
  print('═══════════════════════════════════════════════════════════════');
  print('AUDIT OF ALL BOOKS ACROSS TALIB_ILM LIBRARY');
  print('═══════════════════════════════════════════════════════════════');

  final books = TurathCatalog.books;
  print('Total books in TurathCatalog: ${books.length}');

  // 1. Check for duplicates in TurathCatalog
  final idToBooks = <int, List<ShamelaBook>>{};
  for (final b in books) {
    idToBooks.putIfAbsent(b.id, () => []).add(b);
  }

  int duplicateCount = 0;
  for (final entry in idToBooks.entries) {
    if (entry.value.length > 1) {
      duplicateCount++;
      print('❌ DUPLICATE ID ${entry.key}:');
      for (final b in entry.value) {
        print('   - "${b.title}" by ${b.author} (category: ${b.category})');
      }
    }
  }

  if (duplicateCount == 0) {
    print('✅ Zero duplicate IDs in TurathCatalog.');
  }

  // 2. Check for invalid or suspicious page counts
  int invalidPageCount = 0;
  for (final b in books) {
    if (b.totalPages <= 0) {
      invalidPageCount++;
      print('❌ INVALID PAGE COUNT: [${b.id}] "${b.title}" has totalPages = ${b.totalPages}');
    }
  }
  if (invalidPageCount == 0) {
    print('✅ All ${books.length} books have strictly positive totalPages (> 0).');
  }

  // 3. Category Breakdown
  print('\n── Category Breakdown ──');
  for (final cat in TurathCatalog.disciplines) {
    print('  - ${cat.name} (ID: ${cat.id}): ${cat.count} books');
  }

  // 4. Mutun Digital Catalog Audit
  print('\n── Mutun Digital Catalog (${MutunDigitalCatalog.entries.length} syllabus mutun) ──');
  for (final entry in MutunDigitalCatalog.entries.values) {
    print('  - [${entry.id}] Shamela ID ${entry.shamelaId}: "${entry.title}" (${entry.totalPages} pages)');
  }

  // 5. Mutun Curriculum Catalog Audit
  print('\n── Mutun Curriculum Catalog ──');
  const curriculumBookIds = [
    'bk_adhkar_adab',
    'bk_nawaqid_islam',
    'bk_qawaid_arba',
    'bk_usul_thalatha',
    'bk_shuroot_salah',
    'bk_tuhfat_atfal',
    'bk_manzumah_baiquoni',
  ];
  for (final id in curriculumBookIds) {
    final b = MutunCurriculumCatalog.getBook(id);
    if (b != null) {
      print('  - [$id] "${b.title}": ${b.sections.length} sections, ${b.totalParagraphs} paragraphs');
    } else {
      print('  - [$id] Not in curriculum catalog');
    }
  }

  print('═══════════════════════════════════════════════════════════════');
}
