import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/responsive.dart';
import '../../../app/theme/theme_colors.dart';

/// Search result model
class QuranSearchResult {
  final int surahNumber;
  final String surahName;
  final int verseNumber;
  final String verseText;
  final int pageNumber;

  const QuranSearchResult({
    required this.surahNumber,
    required this.surahName,
    required this.verseNumber,
    required this.verseText,
    required this.pageNumber,
  });
}

/// Search filter type
enum SearchFilter { word, surah, topic, juz }

/// Quran search page
class QuranSearchPage extends StatefulWidget {
  const QuranSearchPage({super.key});

  @override
  State<QuranSearchPage> createState() => _QuranSearchPageState();
}

class _QuranSearchPageState extends State<QuranSearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;

  SearchFilter _selectedFilter = SearchFilter.word;
  List<QuranSearchResult> _results = [];
  List<String> _recentSearches = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('quran_recent_searches') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    await prefs.setStringList('quran_recent_searches', _recentSearches);
  }

  Future<void> _removeRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.remove(query);
    });
    await prefs.setStringList('quran_recent_searches', _recentSearches);
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    await _saveRecentSearch(query);

    // Simulated search results
    await Future.delayed(const Duration(milliseconds: 300));

    final sampleResults = _getSampleResults(query);

    setState(() {
      _results = sampleResults;
      _isSearching = false;
      _hasSearched = true;
    });
  }

  List<QuranSearchResult> _getSampleResults(String query) {
    // Sample data - in real app, search Quran database
    return [
          QuranSearchResult(
            surahNumber: 1,
            surahName: 'الفاتحة',
            verseNumber: 1,
            verseText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            pageNumber: 1,
          ),
          QuranSearchResult(
            surahNumber: 2,
            surahName: 'البقرة',
            verseNumber: 255,
            verseText: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ',
            pageNumber: 42,
          ),
          QuranSearchResult(
            surahNumber: 112,
            surahName: 'الإخلاص',
            verseNumber: 1,
            verseText: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
            pageNumber: 604,
          ),
        ]
        .where(
          (r) => r.verseText.contains(query) || r.surahName.contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : context.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        title: Text(
          'البحث في القرآن',
          style: TextStyle(
            fontSize: responsive.sp(18),
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.grey.shade800,
            fontFamily: 'Cairo',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: responsive.sp(16),
                  color: isDark ? Colors.white : Colors.grey.shade800,
                  fontFamily: 'Cairo',
                ),
                decoration: InputDecoration(
                  hintText: 'ابحث في القرآن الكريم',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontFamily: 'Cairo',
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: const Color(0xFF14B8A6),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _results = [];
                              _hasSearched = false;
                            });
                          },
                          icon: Icon(Icons.close, color: Colors.grey.shade400),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: SearchFilter.values.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getFilterLabel(filter)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                      if (_searchController.text.isNotEmpty) {
                        _performSearch(_searchController.text);
                      }
                    },
                    backgroundColor: isDark
                        ? const Color(0xFF1A1A1A)
                        : Colors.grey.shade100,
                    selectedColor: const Color(
                      0xFF14B8A6,
                    ).withValues(alpha: 0.2),
                    checkmarkColor: const Color(0xFF14B8A6),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF14B8A6)
                          : (isDark ? Colors.white : Colors.grey.shade700),
                      fontFamily: 'Cairo',
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(child: _buildContent(isDark, responsive)),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, Responsive responsive) {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
      );
    }

    if (!_hasSearched && _searchController.text.isEmpty) {
      return _buildRecentSearches(isDark, responsive);
    }

    if (_results.isEmpty) {
      return _buildEmptyState(isDark, responsive);
    }

    return _buildResults(isDark, responsive);
  }

  Widget _buildRecentSearches(bool isDark, Responsive responsive) {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'ابدأ البحث',
              style: TextStyle(
                fontSize: responsive.sp(16),
                color: Colors.grey.shade500,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Text(
          'عمليات البحث الأخيرة',
          style: TextStyle(
            fontSize: responsive.sp(14),
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.grey.shade700,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 12),
        ..._recentSearches.map(
          (query) => Dismissible(
            key: Key(query),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _removeRecentSearch(query),
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16),
              color: Colors.red.shade400,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              onTap: () {
                _searchController.text = query;
                _performSearch(query);
              },
              leading: const Icon(Icons.history, color: Color(0xFF14B8A6)),
              title: Text(
                query,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.grey.shade800,
                  fontFamily: 'Cairo',
                ),
              ),
              trailing: Icon(
                Icons.north_west,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, Responsive responsive) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontSize: responsive.sp(18),
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey.shade700,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب البحث بكلمات مختلفة',
            style: TextStyle(
              fontSize: responsive.sp(14),
              color: Colors.grey.shade500,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(bool isDark, Responsive responsive) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return _SearchResultCard(
          result: result,
          searchQuery: _searchController.text,
          nightMode: isDark,
          onTap: () {
            // Navigate to reading page
            Navigator.pop(context, result);
          },
        );
      },
    );
  }

  String _getFilterLabel(SearchFilter filter) {
    switch (filter) {
      case SearchFilter.word:
        return 'بالكلمة';
      case SearchFilter.surah:
        return 'بالسورة';
      case SearchFilter.topic:
        return 'بالموضوع';
      case SearchFilter.juz:
        return 'بالجزء';
    }
  }
}

class _SearchResultCard extends StatelessWidget {
  final QuranSearchResult result;
  final String searchQuery;
  final bool nightMode;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.result,
    required this.searchQuery,
    required this.nightMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: nightMode ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFF14B8A6), width: 3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'سورة ${result.surahName}',
                        style: TextStyle(
                          fontSize: responsive.sp(12),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF14B8A6),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'آية ${result.verseNumber}',
                      style: TextStyle(
                        fontSize: responsive.sp(12),
                        color: nightMode ? Colors.white : Colors.grey.shade700,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildHighlightedText(
                  result.verseText,
                  searchQuery,
                  nightMode,
                  responsive,
                ),
                const SizedBox(height: 8),
                Text(
                  'صفحة ${result.pageNumber}',
                  style: TextStyle(
                    fontSize: responsive.sp(11),
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    bool nightMode,
    Responsive responsive,
  ) {
    if (query.isEmpty || !text.contains(query)) {
      return Text(
        text,
        style: TextStyle(
          fontSize: responsive.sp(18),
          color: nightMode ? Colors.white : Colors.grey.shade800,
          fontFamily: 'Amiri',
          height: 1.8,
        ),
        textDirection: TextDirection.rtl,
      );
    }

    final spans = <TextSpan>[];
    final parts = text.split(query);

    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(
          TextSpan(
            text: query,
            style: TextStyle(
              backgroundColor: const Color(0xFFFEF3C7),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
    }

    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: TextStyle(
          fontSize: responsive.sp(18),
          color: nightMode ? Colors.white : Colors.grey.shade800,
          fontFamily: 'Amiri',
          height: 1.8,
        ),
        children: spans,
      ),
    );
  }
}
