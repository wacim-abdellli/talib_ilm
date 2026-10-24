import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/location_service.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/icon_badge.dart';

/// User-controlled explicit opt-in toggle for remote reverse geocoding.
///
/// Strictly defaults to false (off). Explains the third-party recipient
/// (BigDataCloud) and exact purpose (city name lookup when offline
/// catalog does not match) before any coordinates can be transmitted.
class RemoteGeocodingConsentTile extends StatefulWidget {
  final ValueChanged<bool>? onChanged;

  const RemoteGeocodingConsentTile({super.key, this.onChanged});

  @override
  State<RemoteGeocodingConsentTile> createState() =>
      _RemoteGeocodingConsentTileState();
}

class _RemoteGeocodingConsentTileState
    extends State<RemoteGeocodingConsentTile> {
  bool _allowed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final allowed = await LocationService.isRemoteGeocodingAllowed();
    if (!mounted) return;
    setState(() {
      _allowed = allowed;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _allowed = value);
    await LocationService.setRemoteGeocodingAllowed(value);
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBadge(icon: Icons.travel_explore_rounded),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'البحث عن اسم المدينة عبر الإنترنت',
                  style: context.text.body.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(
                  'يسمح بإرسال الإحداثيات إلى (BigDataCloud) لجلب اسم المدينة بالعربية فقط عند تعذر التعرف عليها محلياً. معطل افتراضياً لحماية الخصوصية.',
                  style: context.text.caption.copyWith(
                    color: palette.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSize.tap,
              minHeight: AppSize.tap,
            ),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Semantics(
                      label: 'البحث عن اسم المدينة عبر الإنترنت',
                      toggled: _allowed,
                      child: Switch(
                        value: _allowed,
                        onChanged: _toggle,
                        activeThumbColor: palette.primary,
                        activeTrackColor: palette.primarySoft,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
