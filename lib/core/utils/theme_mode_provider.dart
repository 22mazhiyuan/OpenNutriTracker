import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/app_look.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';

class ThemeModeProvider extends ChangeNotifier {
  AppThemeEntity appTheme;
  AppLook appLook;
  // #415: whether to harmonise the app palette with the system wallpaper
  // when one is available (Android 12+). On other platforms the static
  // palette is used regardless, so the toggle has no visible effect.
  bool useMaterialYou;
  // #415 follow-up: custom accent colour packed as 32-bit ARGB; overrides
  // Material You when set. Null means "use the platform default".
  int? accentColor;

  ThemeModeProvider({
    required this.appTheme,
    this.appLook = AppLook.glass,
    this.useMaterialYou = true,
    this.accentColor,
  }) {
    AppPalette.activeLook = appLook;
  }

  ThemeMode get themeMode => appTheme.toThemeMode();

  void updateTheme(AppThemeEntity appTheme) {
    this.appTheme = appTheme;
    notifyListeners();
  }

  void updateUseMaterialYou(bool value) {
    if (useMaterialYou == value) return;
    useMaterialYou = value;
    notifyListeners();
  }

  void updateAccentColor(int? value) {
    if (accentColor == value) return;
    accentColor = value;
    notifyListeners();
  }

  void updateLook(AppLook value) {
    if (appLook == value) return;
    appLook = value;
    AppPalette.activeLook = value;
    notifyListeners();
  }
}
