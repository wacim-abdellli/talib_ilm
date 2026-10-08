import 'package:flutter/foundation.dart';

void enableBadCertificateCatcher() {
  // Web does not support HttpOverrides (handled by browser)
  debugPrint('Bad certificate catcher ignored for web');
}
