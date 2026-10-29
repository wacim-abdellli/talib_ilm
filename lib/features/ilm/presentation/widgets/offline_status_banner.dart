import 'package:flutter/material.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/offline_connectivity_service.dart';

/// Calm Scholar offline notification banner.
/// Automatically appears when internet disconnects and provides 1-tap jump to downloaded hub.
class OfflineStatusBanner extends StatefulWidget {
  final VoidCallback onOpenDownloadsHub;

  const OfflineStatusBanner({
    super.key,
    required this.onOpenDownloadsHub,
  });

  @override
  State<OfflineStatusBanner> createState() => _OfflineStatusBannerState();
}

class _OfflineStatusBannerState extends State<OfflineStatusBanner> {
  final OfflineConnectivityService _connectivityService =
      OfflineConnectivityService();
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return ValueListenableBuilder<bool>(
      valueListenable: _connectivityService.isOfflineNotifier,
      builder: (context, isOffline, _) {
        if (!isOffline || _isDismissed) {
          return const SizedBox.shrink();
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpace.lg,
              0,
              AppSpace.lg,
              AppSpace.sm,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: palette.surfaceRaised,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(
                  color: palette.gold.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpace.md,
                AppSpace.sm,
                AppSpace.xs,
                AppSpace.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: AppSize.tap,
                    height: AppSize.tap,
                    decoration: BoxDecoration(
                      color: palette.goldSoft,
                      borderRadius: AppRadius.smRadius,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.cloud_off_rounded,
                      color: palette.gold,
                      size: AppIcon.md,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'وضع عدم الاتصال بالإنترنت',
                          style: textTheme.caption.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          'تصفح كتبك وسورك الصوتية المحمّلة',
                          style: textTheme.caption.copyWith(
                            color: palette.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppSize.tap,
                      minHeight: AppSize.tap,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: AppRadius.smRadius,
                        onTap: widget.onOpenDownloadsHub,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.sm,
                            vertical: AppSpace.xs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'المحملات',
                                style: textTheme.caption.copyWith(
                                  color: palette.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: AppSpace.xxs),
                              Icon(
                                Icons.chevron_left_rounded,
                                color: palette.primary,
                                size: AppIcon.sm,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: palette.textMuted,
                      size: AppIcon.sm,
                    ),
                    tooltip: 'إغلاق التنبيه',
                    onPressed: () {
                      setState(() => _isDismissed = true);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
