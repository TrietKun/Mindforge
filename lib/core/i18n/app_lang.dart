import 'package:flutter/foundation.dart';

enum AppLang { vi, en }

/// App-wide selected language. Toggling rebuilds the whole app.
final ValueNotifier<AppLang> appLang = ValueNotifier(AppLang.vi);

/// Picks the right string for the current language.
String L(String vi, String en) => appLang.value == AppLang.vi ? vi : en;

void toggleLang() =>
    appLang.value = appLang.value == AppLang.vi ? AppLang.en : AppLang.vi;
