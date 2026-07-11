import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0D1117);
  static const bg2 = Color(0xFF161B22);
  static const bg3 = Color(0xFF1C2333);
  static const bg4 = Color(0xFF21262D);
  static const border = Color(0xFF30363D);
  static const text1 = Color(0xFFE6EDF3);
  static const text2 = Color(0xFF8B949E);
  static const text3 = Color(0xFF6E7681);
  static const accent = Color(0xFF7C3AED);
  static const accentLight = Color(0xFFA78BFA);
  static const blue = Color(0xFF58A6FF);
  static const green = Color(0xFF3FB950);
  static const amber = Color(0xFFD29922);
  static const red = Color(0xFFF85149);
  static const purple = Color(0xFFBC8CFF);
  static const cyan = Color(0xFF79C0FF);
}

@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color bg;
  final Color bg2;
  final Color bg3;
  final Color bg4;
  final Color border;
  final Color text1;
  final Color text2;
  final Color text3;
  final Color accent;
  final Color accentLight;
  final Color blue;
  final Color green;
  final Color amber;
  final Color red;
  final Color purple;
  final Color cyan;

  const AppColorsExtension({
    required this.bg,
    required this.bg2,
    required this.bg3,
    required this.bg4,
    required this.border,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.accent,
    required this.accentLight,
    required this.blue,
    required this.green,
    required this.amber,
    required this.red,
    required this.purple,
    required this.cyan,
  });

  static const dark = AppColorsExtension(
    bg: AppColors.bg,
    bg2: AppColors.bg2,
    bg3: AppColors.bg3,
    bg4: AppColors.bg4,
    border: AppColors.border,
    text1: AppColors.text1,
    text2: AppColors.text2,
    text3: AppColors.text3,
    accent: AppColors.accent,
    accentLight: AppColors.accentLight,
    blue: AppColors.blue,
    green: AppColors.green,
    amber: AppColors.amber,
    red: AppColors.red,
    purple: AppColors.purple,
    cyan: AppColors.cyan,
  );

  static const light = AppColorsExtension(
    bg: Color(0xFFF6F8FA),
    bg2: Color(0xFFFFFFFF),
    bg3: Color(0xFFEAEEF2),
    bg4: Color(0xFFE7EAED),
    border: Color(0xFFD0D7DE),
    text1: Color(0xFF1F2328),
    text2: Color(0xFF59636E),
    text3: Color(0xFF6E7781),
    accent: AppColors.accent,
    accentLight: Color(0xFF6D28D9),
    blue: Color(0xFF0969DA),
    green: Color(0xFF1A7F37),
    amber: Color(0xFF9A6700),
    red: Color(0xFFCF222E),
    purple: Color(0xFF8250DF),
    cyan: Color(0xFF1B7C83),
  );

  @override
  AppColorsExtension copyWith({
    Color? bg,
    Color? bg2,
    Color? bg3,
    Color? bg4,
    Color? border,
    Color? text1,
    Color? text2,
    Color? text3,
    Color? accent,
    Color? accentLight,
    Color? blue,
    Color? green,
    Color? amber,
    Color? red,
    Color? purple,
    Color? cyan,
  }) {
    return AppColorsExtension(
      bg: bg ?? this.bg,
      bg2: bg2 ?? this.bg2,
      bg3: bg3 ?? this.bg3,
      bg4: bg4 ?? this.bg4,
      border: border ?? this.border,
      text1: text1 ?? this.text1,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      accent: accent ?? this.accent,
      accentLight: accentLight ?? this.accentLight,
      blue: blue ?? this.blue,
      green: green ?? this.green,
      amber: amber ?? this.amber,
      red: red ?? this.red,
      purple: purple ?? this.purple,
      cyan: cyan ?? this.cyan,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      bg: Color.lerp(bg, other.bg, t)!,
      bg2: Color.lerp(bg2, other.bg2, t)!,
      bg3: Color.lerp(bg3, other.bg3, t)!,
      bg4: Color.lerp(bg4, other.bg4, t)!,
      border: Color.lerp(border, other.border, t)!,
      text1: Color.lerp(text1, other.text1, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      text3: Color.lerp(text3, other.text3, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      green: Color.lerp(green, other.green, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      red: Color.lerp(red, other.red, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>()!;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.bg2,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg2,
        foregroundColor: AppColors.text1,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.text1,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bg2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.text2),
        hintStyle: const TextStyle(color: AppColors.text3),
      ),
      dividerColor: AppColors.border,
      extensions: const [AppColorsExtension.dark],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF6F8FA),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1F2328),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFD0D7DE), width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsExtension.light.bg3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorsExtension.light.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorsExtension.light.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorsExtension.light.accent, width: 1.5),
        ),
        labelStyle: TextStyle(color: AppColorsExtension.light.text2),
        hintStyle: TextStyle(color: AppColorsExtension.light.text3),
      ),
      dividerColor: AppColorsExtension.light.border,
      extensions: const [AppColorsExtension.light],
    );
  }
}
