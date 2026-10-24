import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/icon_badge.dart';
import '../../../shared/widgets/primary_app_bar.dart';

/// Screen displaying all official data sources, scholarship attributions,
/// software licenses, and the application's transparent privacy policy.
class CreditsAndLicensesPage extends StatelessWidget {
  const CreditsAndLicensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: const PrimaryAppBar(
        title: 'المصادر والتراخيص',
        showBack: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsetsDirectional.only(
            start: AppSpace.lg,
            end: AppSpace.lg,
            top: AppSpace.md,
            bottom: AppSpace.xxl + 48,
          ),
          children: [
            // ── 1. Sacred Veneration Notice ──────────────────────────────────
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.lg),
              decoration: BoxDecoration(
                color: palette.goldSoft.withValues(alpha: 0.15),
                borderRadius: AppRadius.lgRadius,
                border: Border.all(
                  color: palette.gold.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: palette.gold,
                    size: AppIcon.md,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ضبط النص القرآني الشريف',
                          style: textTheme.body.copyWith(
                            color: palette.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          'يُعرض نص القرآن الكريم برواية حفص عن عاصم بالرسم العثماني المعتمد لمصحف المدينة النبوية، مستمداً مباشرة من مجمع الملك فهد لطباعة المصحف الشريف، دون أي تعديل أو تصرف في النص القرآني أو فواصل الآيات.',
                          style: textTheme.caption.copyWith(
                            color: palette.text,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpace.lg),

            // ── 2. Data Sources & Attributions ──────────────────────────────
            Text(
              'مصادر البيانات المعتمدة',
              style: textTheme.titleSmall.copyWith(
                color: palette.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpace.sm),

            _SourceCard(
              title: 'مجمع الملك فهد لطباعة المصحف الشريف',
              subtitle: 'المدينة المنورة، المملكة العربية السعودية',
              description:
                  'خطوط الرسم العثماني الرقمية لمصحف المدينة النبوية (15 سطراً لكل صفحة)، وبيانات تجزئة الصفحات والسور والآيات.',
              icon: Icons.menu_book_rounded,
              iconColor: palette.primary,
            ),

            const SizedBox(height: AppSpace.sm),

            _SourceCard(
              title: 'التلاوات الصوتية (EveryAyah.com)',
              subtitle: 'تسجيلات المصحف المرتل لكبار القراء',
              description:
                  'تلاوات الآيات القرآنية بصوت:\n• الشيخ مشاري بن راشد العفاسي\n• الشيخ محمود خليل الحصري\n• الشيخ محمد صديق المنشاوي\n• الشيخ عبد الباسط عبد الصمد\n• الشيخ سعد الغامدي',
              icon: Icons.record_voice_over_rounded,
              iconColor: palette.gold,
            ),

            const SizedBox(height: AppSpace.sm),

            _SourceCard(
              title: 'التفاسير ومعاني الكلمات (Quran.com API)',
              subtitle: 'واجهة البيانات القرآنية المفتوحة',
              description:
                  'خدمات جلب التفاسير المعتمدة لأهل السنة والجماعة، وبيانات معاني المفردات وغريب القرآن كلمة بكلمة.',
              icon: Icons.auto_stories_rounded,
              iconColor: palette.primary,
            ),

            const SizedBox(height: AppSpace.sm),

            _SourceCard(
              title: 'تفاسير أهل السنة المعتمدة',
              subtitle: 'أمهات كتب التفسير الإسلامي',
              description:
                  '• التفسير الميسر (نخبة من العلماء - مجمع الملك فهد)\n• تيسير الكريم الرحمن (الشيخ عبد الرحمن بن ناصر السعدي)\n• تفسير القرآن العظيم (الحافظ ابن كثير الدمشقي)\n• معالم التنزيل (الإمام البغوي)',
              icon: Icons.library_books_rounded,
              iconColor: palette.success,
            ),

            const SizedBox(height: AppSpace.lg),

            // ── 3. Open Source Licenses ──────────────────────────────────────
            Text(
              'التراخيص البرمجية',
              style: textTheme.titleSmall.copyWith(
                color: palette.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpace.sm),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const IconBadge(icon: Icons.code_rounded),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الحزم مفتوحة المصدر (Third-party)',
                              style: textTheme.body.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'حزمة qcf_quran_plus (ترخيص MIT) وجميع حزم Flutter',
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  AppButton.outline(
                    label: 'عرض قائمة التراخيص القانونية الكاملة',
                    icon: Icons.description_outlined,
                    onPressed: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'طالب علم',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            'تطبيق إسلامي رقمي مجاني لخدمة القرآن الكريم وعلوم الشريعة.',
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpace.lg),

            // ── 4. Privacy Policy ───────────────────────────────────────────
            Text(
              'سياسة الخصوصية وحماية البيانات',
              style: textTheme.titleSmall.copyWith(
                color: palette.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpace.sm),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        color: palette.primary,
                        size: AppIcon.md,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Text(
                        'خصوصية تامة بدون جمع بيانات',
                        style: textTheme.body.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    '1. لا جمع للبيانات الشخصية:\nالتطبيق لا يطلب أي تسجيل دخول أو حساب، ولا يجمع أو يشارك أي بيانات شخصية أو بريد إلكتروني.\n\n2. التخزين المحلي فقط:\nجميع محفوظاتك وفواصل القراءة والملاحظات الإيمانية وإعدادات السمة مخزنة محلياً على هاتفك فقط.\n\n3. الاتصال بالإنترنت:\nيقتصر الاتصال بالإنترنت على جلب نصوص التفسير (Quran.com) وتشغيل التلاوات الصوتية (EveryAyah.com)، مع حساب مواقيت الصلاة محلياً على الجهاز بالكامل دون إرسال الإحداثيات لأي مزود خارجي (سواء خوادم النظام أو BigDataCloud) إلا عند تفعيل خيار البحث عن اسم المدينة صراحة من الإعدادات.\n\n4. خلو تام من الإعلانات:\nالتطبيق مجاني وخالٍ تماماً من أي إعلانات تجارية أو حزم تعقب تحليلي.',
                    style: textTheme.caption.copyWith(
                      color: palette.textMuted,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color iconColor;

  const _SourceCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: AppIcon.sm),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.body.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            description,
            style: textTheme.caption.copyWith(
              color: palette.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
