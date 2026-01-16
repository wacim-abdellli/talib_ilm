class AppStrings {
  AppStrings._();

  static const String appName = 'طالب العلم';
  static const String appTagline = ' تطبيق إرشادي لطالب العلم';
  static const String appVersion = '1.0.1';

  static const String navHome = 'الرئيسية';
  static const String navIlm = 'العلم';
  static const String navAdhkar = 'الأذكار';
  static const String navPrayer = 'الصلاة';
  static const String navLibrary = 'المكتبة';
  static const String navFavorites = 'المفضلة';
  static const String navMore = 'المزيد';
  static const String navSettings = 'الإعدادات';
  static const String navAbout = 'حول التطبيق';

  static const String tooltipMenu = 'القائمة';
  static const String tooltipBack = 'رجوع';

  static const String actionClose = 'إغلاق';
  static const String actionBack = 'رجوع';
  static const String actionRetry = 'إعادة المحاولة';
  static const String actionSave = 'حفظ';
  static const String actionUpdate = 'تحديث';
  static const String actionShare = 'مشاركة';
  static const String actionReset = 'إعادة تعيين';
  static const String actionOptions = 'الخيارات';
  static const String actionDetails = 'التفاصيل';
  static const String actionCopy = 'نسخ';
  static const String actionStartNow = 'ابدأ الآن';
  static const String actionContinue = 'متابعة';
  static const String actionReadFull = 'قراءة كاملة';
  static const String actionShowLess = 'عرض أقل';
  static const String favoriteAdd = 'إضافة إلى المفضلة';
  static const String favoriteRemove = 'إزالة من المفضلة';
  static const String copyDone = 'تم النسخ';

  static const String greeting = 'السلام عليكم';

  static const String homeStartLearningTitle = 'ابدأ الطلب';
  static const String homeStartLearningMessage =
      'ابدأ بالمتن المناسب للتدرج المنهجي في العلم.';
  static const String homeSectionLabel = 'القسم';
  static const String homeProgressLabel = 'التقدم';
  static const String progressUnknown = '—';
  static String sectionValue(String value) => '$homeSectionLabel: $value';
  static String percentLabel(int percent) => '$percent%';
  static String numberPair(int current, int total) =>
      '\u2066$current / $total\u2069';
  static const String homeHadithTitle = 'حديث اليوم';
  static const String homeDhikrTitle = 'ذكر اليوم';
  static const String dailyMotivationFallback = 'العلم قبل القول والعمل';

  static String lastRead(String section) => 'آخر قراءة: $section';
  static String lastReadSharh(String title) => 'آخر قراءة: الشرح — $title';
  static const String lastActivityLessons = 'آخر نشاط: الدروس';
  static String sourcePrefix(String source) => '— $source';
  static String lastPage(int page, [int? total]) => total == null || total == 0
      ? 'آخر صفحة: $page'
      : 'آخر صفحة: ${numberPair(page, total)}';

  static const String continueTabMutn = 'المتن';
  static const String continueTabSharh = 'الشرح';
  static const String continueTabLessons = 'الدروس';

  static const String prayerTitle = 'الصلاة';
  static const String prayerDayLabel = 'اليوم';
  static const String prayerNext = 'الصلاة القادمة';
  static const String prayerCurrent = 'الصلاة الحالية';
  static const String prayerFajr = 'الفجر';
  static const String prayerDhuhr = 'الظهر';
  static const String prayerAsr = 'العصر';
  static const String prayerMaghrib = 'المغرب';
  static const String prayerIsha = 'العشاء';
  static const List<String> prayerOrder = [
    prayerFajr,
    prayerDhuhr,
    prayerAsr,
    prayerMaghrib,
    prayerIsha,
  ];
  static String prayerRemaining(String value) => 'متبقي: $value';
  static String prayerRemainingShort(String value) => 'متبقي $value';
  static String prayerInMinutes(int minutes) => 'بعد $minutes دقيقة';
  static const String prayerLocationSettings = 'إعدادات الموقع';
  static const String prayerLoadErrorTitle = 'تعذر تحميل أوقات الصلاة';
  static const String prayerLoadErrorMessage =
      'تحقق من إعدادات الموقع ثم أعد المحاولة.';
  static const String prayerCurrentBadge = 'الحالية';
  static const String prayerNextBadge = 'القادمة';
  static const String beforePrayerDhikr = 'أذكار قبل الصلاة';
  static const String afterPrayerDhikr = 'أذكار بعد الصلاة';
  static String afterPrayerTitle(String? prayerName) =>
      prayerName == null ? 'بعد الصلاة' : 'بعد صلاة $prayerName';

  static const String qiblaTitle = 'اتجاه القبلة';
  static const String qiblaComingSoon = 'بوصلة القبلة قادمة بإذن الله';

  static const String locationSettingsTitle = 'إعدادات الموقع';
  static const String locationManualToggle = 'استخدام موقع يدوي';
  static const String locationManualCityLabel = 'المدينة (اختياري)';
  static const String locationLatitudeLabel = 'خط العرض (Latitude)';
  static const String locationLongitudeLabel = 'خط الطول (Longitude)';
  static const String locationSave = 'حفظ الموقع';
  static const String locationBackToAuto = 'العودة للموقع التلقائي';
  static const String locationInvalidMessage =
      'أدخل خط العرض وخط الطول بشكل صحيح.';
  static const String locationDefaultCity = 'مكة المكرمة';
  static const String locationManualDefault = 'الموقع اليدوي';
  static const String locationCurrent = 'الموقع الحالي';

  static const String adhanSettingsTitle = 'إعدادات الأذان';
  static String adhanEnabledCount(int enabled, int total) =>
      'مفعّل $enabled من $total';
  static const String adhanEnableToggle = 'تفعيل الأذان';
  static const String adhanPerPrayer = 'تفعيل لكل صلاة';
  static const String adhanSelect = 'اختيار الأذان';
  static const String adhanMakkah = 'مكة';
  static const String adhanMadinah = 'المدينة';
  static const String adhanSilentOnly = 'إشعارات صامتة فقط';
  static const String adhanTest = 'تشغيل الأذان للتجربة';
  static const String prayerNotificationTitle = 'حان وقت الصلاة';
  static String prayerNotificationBody(String prayerName) =>
      'حان الآن وقت صلاة $prayerName';
  static const String notificationChannelName = 'Prayer Times';
  static const String notificationChannelDescription = 'Prayer time reminders';
  static const String notificationDefaultAction = 'Open';

  static const String favoritesTitle = 'المفضلة';
  static const String favoritesEmptyTitle = 'المفضلة فارغة';
  static const String favoritesEmptyMessage =
      'اجعل هذا المكان مرجعًا لفوائدك المنتقاة.';
  static const String favoritesRemoveTooltip = 'إزالة من المفضلة';

  static const String adhkarTitle = 'الأذكار';
  static const String adhkarMorning = 'أذكار الصباح';
  static const String adhkarEvening = 'أذكار المساء';
  static const String adhkarAfterPrayer = 'أذكار بعد الصلاة';
  static const String adhkarBeforePrayer = 'أذكار قبل الصلاة';
  static const String adhkarGeneral = 'أذكار متنوعة';
  static const String adhkarMorningSubtitle = 'بداية هادئة لليوم';
  static const String adhkarEveningSubtitle = 'ختام مطمئن للمساء';
  static const String adhkarAfterPrayerSubtitle = 'ذكر بعد التسليم';
  static const String adhkarFreeCountSubtitle = 'تسبيح مطلق';
  static const String adhkarDuasSubtitle = 'قراءة هادئة بدون عدّ';
  static const String adhkarLoadErrorTitle = 'تعذر تحميل الأذكار';
  static const String adhkarLoadErrorMessage = 'حاول مرة أخرى بعد قليل.';
  static const String adhkarEmptyTitle = 'لا يوجد محتوى حاليًا';
  static const String adhkarEmptyMessage = 'نعدّ لك محتوى نافعًا، فترقبه.';
  static const String adhkarSessionEmptyTitle = 'لا توجد أذكار';
  static const String adhkarSessionEmptyMessage = 'يمكنك اختيار مجموعة أخرى.';
  static const String adhkarSource = 'المصدر';
  static const String adhkarVirtue = 'الفضل';
  static const String adhkarOptions = 'الخيارات';
  static const String adhkarDetails = 'التفاصيل';
  static const String adhkarResetCount = 'إعادة العد';
  static const String adhkarCopyText = 'نسخ النص';
  static const String adhkarShare = 'مشاركة';
  static const String adhkarPronunciation = 'النطق';
  static const String adhkarMeaning = 'المعنى';
  static String adhkarRepeatLabel(int count, int repeat) =>
      'التكرار: ${numberPair(count, repeat)}';

  static const String tasbeehTitle = 'تسبيح واستغفار';
  static const String tasbeehTab = 'تسبيح';
  static const String istighfarTab = 'استغفار';
  static const String tasbeehDefault = 'سبحان الله';
  static const String istighfarDefault = 'أستغفر الله';
  static const String targetTitle = 'تحديد الهدف';
  static const String targetHint = 'مثال: 33';
  static const String targetCancel = 'إلغاء';
  static const String targetNoGoal = 'بدون هدف';
  static const String targetSave = 'حفظ';
  static const String targetCompleted = 'تم إكمال الهدف';
  static const String changeDhikr = 'تغيير الذكر';
  static const String setTarget = 'تحديد الهدف';
  static const String reset = 'إعادة';
  static const String tapToCountNoTarget = 'اضغط للعد • بدون هدف';
  static String targetLabel(int target) => 'الهدف: $target';
  static const String targetHintMessage = 'يمكنك تحديد هدف حسب رغبتك';
  static String progressLabel(int count, int target) =>
      'التقدم: ${numberPair(count, target)}';

  static const String duasTitle = 'أدعية وأذكار';
  static const String duasEmptyTitle = 'لا توجد أدعية متاحة';
  static const String duasEmptyMessage = 'أضف الأدعية ثم أعد المحاولة.';

  static const String ilmTitle = 'العلم';
  static const String ilmLoadErrorTitle = 'تعذر تحميل المنهج';
  static const String ilmLoadErrorMessage = 'حاول مرة أخرى بعد قليل.';
  static String levelLabel(int order) => 'المستوى $order';
  static const String levelClosed = 'مغلق';
  static String levelCompleted(int count) => 'مكتمل $count';
  static String levelInProgress(int count) => 'قيد التقدم $count';
  static String levelProgress(int completed, int total) =>
      '$completed من $total كتب';
  static const String levelProgressTitle = 'تقدم المرحلة';
  static String levelCompletedSummary(int completed, int total) =>
      '${numberPair(completed, total)} كتب مكتملة';
  static const String viewBooks = 'عرض الكتب';

  static const String levelNotStartedTitle = 'لم تبدأ هذه المرحلة بعد';
  static const String levelNotStartedMessage =
      'ابدأ بأول كتاب لتسير مع العلم خطوة بخطوة.';

  static const String bookProgressSaved = 'تم حفظ التقدم';
  static const String bookFavoriteAdd = 'إضافة إلى المفضلة';
  static const String bookFavoriteRemove = 'إزالة من المفضلة';
  static const String bookResetProgress = 'إعادة تعيين التقدم';
  static const String bookMutnTab = 'المتن';
  static const String bookSharhTab = 'الشرح';
  static const String bookLessonsTab = 'الدروس';
  static const String bookMutnTitle = 'المتن';
  static const String bookMutnEmptyTitle = 'المتن غير متاح';
  static const String bookMutnEmptyMessage =
      'سيتم توفير المتن قريباً بإذن الله.';
  static const String bookSharhEmptyTitle = 'لا توجد شروح متاحة بعد';
  static const String bookSharhEmptyMessage =
      'ابدأ بالمتن وسنضيف الشروح قريبًا بإذن الله.';
  static const String bookSharhEmptyAction = 'عرض المتن';
  static const String bookLessonsEmptyTitle = 'لا توجد دروس متاحة بعد';
  static const String bookLessonsEmptyMessage =
      'ابدأ بالمتن وسنضيف الدروس قريبًا بإذن الله.';
  static const String bookLessonsEmptyAction = 'العودة للمتن';
  static const String bookShowLessons = 'عرض الدروس';
  static const String difficultyBeginner = 'مبتدئ';
  static const String difficultyIntermediate = 'متوسط';
  static const String difficultyAdvanced = 'متقدم';
  static const String continueSharh = 'متابعة الشرح';
  static const String lastReadSharhBadge = 'آخر شرح قُرئ';
  static const String recommendedBadge = 'مقترح';

  static const String lessonProgressSaved = 'تم حفظ التقدم';
  static String lessonTitle(int index) => 'الدرس ${index + 1}';
  static String lessonDuration(int minutes) => '⏱ $minutes دقيقة';
  static const String lessonNext = 'التالي';

  static const String pdfJumpTitle = 'الانتقال لصفحة';
  static const String pdfJumpCancel = 'إلغاء';
  static const String pdfJumpStart = 'البداية';
  static const String pdfJumpGo = 'انتقال';
  static String pageRangeHint(int total) => '\u20661 - $total\u2069';
  static String pageCounter(int page, int total) => numberPair(page, total);

  static const String libraryTitle = 'المكتبة';
  static const String libraryMutunTitle = 'كل ملفات المتون';
  static const String libraryMutunSubtitle = 'تصفح جميع ملفات PDF للمتون.';
  static const String libraryShuruhTitle = 'كل الشروح';
  static const String libraryShuruhSubtitle = 'الشروح المرتبطة بالكتب.';
  static const String libraryBookmarksTitle = 'الصفحات المحفوظة';
  static const String libraryBookmarksSubtitle = 'العودة لأهم الصفحات بسرعة.';
  static const String libraryDownloadsTitle = 'الفيديوهات المحملة';
  static const String libraryDownloadsSubtitle =
      'عرض المقاطع المتاحة دون اتصال.';

  static const String moreTitle = 'الإعدادات';
  static const String moreSectionTitle = 'المزيد';
  static const String moreGeneralTitle = 'الإعدادات';
  static const String moreGeneralSubtitle = 'إعدادات عامة للتطبيق.';
  static const String moreThemeTitle = 'المظهر';
  static const String moreThemeSubtitle = 'الوضع الداكن والخيارات المستقبلية.';
  static const String moreLanguageTitle = 'اللغة';
  static const String moreLanguageSubtitle = 'إدارة اللغة والترجمة لاحقًا.';
  static const String moreBackupTitle = 'النسخ الاحتياطي والاستعادة';
  static const String moreBackupSubtitle = 'حفظ التقدم واستعادته بسهولة.';
  static const String moreGeneralInfo = 'سيتم توسيع الإعدادات قريبًا.';
  static const String moreThemeInfo = 'تغيير المظهر قيد الإعداد.';
  static const String moreLanguageInfo = 'إدارة اللغة ستتوفر قريبًا.';
  static const String moreBackupInfo = 'النسخ الاحتياطي قيد الإعداد حاليًا.';

  static const String favoriteTypeHadith = 'الأحاديث';
  static const String favoriteTypeDhikr = 'الأذكار';
  static const String favoriteTypeDua = 'الأدعية';
  static const String favoriteTypeLesson = 'الدروس';
  static const String favoriteTypeBook = 'الكتب';

  static const String progressStatusCompleted = 'مكتمل';
  static const String progressStatusInProgress = 'قيد التقدم';
  static const String progressStatusNotStarted = 'لم يبدأ';
  static const String progressStatusNew = 'جديد';

  static const String videoUnsupported =
      'تشغيل الفيديو غير مدعوم على Linux\nسيعمل على Android و iOS';

  // ═══════════════════════════════════════════
  // DAILY READING & MOTIVATION
  // ═══════════════════════════════════════════
  static const String dailyGoalTitle = 'ورد اليوم';
  static String dailyGoalPages(int pages) => 'المطلوب: $pages صفحات';
  static String dailyGoalRemaining(int pages) =>
      pages == 1 ? 'بقيت صفحة واحدة' : 'بقيت $pages صفحات';
  static String dailyGoalProgress(int read, int goal) => '$read من $goal';
  static const String dailyGoalCompleted = 'فتح الله عليك، أتممت وردك اليومي';
  static String streakDays(int days) => '$days أيام مواظبة';
  static const String streakLabel = 'سجل العزم';
  static const String noStreakYet = 'اعزم على البدء اليوم';

  // ═══════════════════════════════════════════
  // START JOURNEY (NEW USERS)
  // ═══════════════════════════════════════════
  static const String startJourneyTitle = 'استعن بالله وابدأ الطلب';
  static const String startJourneySubtitle = 'بداية مقترحة لطالب العلم';
  static const String startJourneyHadith =
      '«من سلك طريقًا يلتمس فيه علمًا سهّل الله له به طريقًا إلى الجنة»';
  static const String startJourneyButton = 'بسم الله أبدأ';

  // ═══════════════════════════════════════════
  // BOOK STATES
  // ═══════════════════════════════════════════
  static const String bookStateNotStarted = 'لم يُبدأ';
  static const String bookStateInProgress = 'قيد الدرس';
  static const String bookStateCompleted = 'أُنجِز';
  static const String bookStateRecommended = 'مختار لك';

  // ═══════════════════════════════════════════
  // CONTINUE READING
  // ═══════════════════════════════════════════
  // ═══════════════════════════════════════════
  // CONTINUE READING
  // ═══════════════════════════════════════════
  static const String continueReading = 'استكمال الورد';
  static const String continueReadingButton = 'متابعة القراءة';
  static String timeToFinishChapter(int minutes) => '⏱️ ~$minutes دقيقة';
  static String pageOfTotal(int current, int total) =>
      'الصفحة $current من $total';

  static const String welcomeBackTitle = 'الحمد لله على عودتك';
  static const String welcomeBackMessage = 'ابدأ بداية جديدة اليوم بعزم قوي';
  static const String startFreshButton = 'بسم الله، صفحة جديدة';

  // ═══════════════════════════════════════════
  // LEVEL PROGRESS
  // ═══════════════════════════════════════════
  static const String levelLocked = 'غير متاح';
  static String levelProgressPercent(int percent) => '$percent٪';
  static const String levelCompleteIcon = '✓';
  static const String startHereLabel = 'نقطة الانطلاق';
  static String levelBooksCount(int count) => '$count متون';

  // ═══════════════════════════════════════════
  // CELEBRATIONS
  // ═══════════════════════════════════════════
  // ═══════════════════════════════════════════
  // CELEBRATIONS
  // ═══════════════════════════════════════════
  static const String celebrationDailyGoal = 'زادك الله حرصًا، أتممت الورد 🎉';
  static const String celebrationKeepStreak =
      'داوم على الخير، فالله يحب المداومة 🔥';
  static const String celebrationBookComplete = 'هنيئًا لك إتمام هذا المتن 📚';
  static const String celebrationLevelComplete = 'بلغت منزلة جديدة في العلم 🏆';
}
