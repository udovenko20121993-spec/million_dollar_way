import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Defines the primary palette for the application and keeps dark/light
/// variants grouped for easy switching in the future.
@immutable
class AppColorSet {
  final Color primaryBackground;
  final Color surfaceBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color accentPositive;
  final Color accentNegative;
  final Color accentInteractive;
  final Color accentHighlight;
  final Color dividerColor;

  const AppColorSet({
    required this.primaryBackground,
    required this.surfaceBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.accentPositive,
    required this.accentNegative,
    required this.accentInteractive,
    required this.accentHighlight,
    required this.dividerColor,
  });

  static const dark = AppColorSet(
    primaryBackground: Color(0xFF1C1C1E),
    surfaceBackground: Color(0xFF2C2C2E),
    primaryText: Color(0xFFF0F0F0),
    secondaryText: Color(0xFFB0B0B0),
    accentPositive: Color(0xFF00B16A),
    accentNegative: Color(0xFFCC3333),
    accentInteractive: Color(0xFF3A7DCD),
    accentHighlight: Color(0xFFD4AF37),
    dividerColor: Color(0xFF404040),
  );

  /// High-contrast light palette prepared for future toggling.
  static const highContrastLight = AppColorSet(
    primaryBackground: Color(0xFFF5F5F7),
    surfaceBackground: Color(0xFFFFFFFF),
    primaryText: Color(0xFF0F0F0F),
    secondaryText: Color(0xFF4A4A4A),
    accentPositive: Color(0xFF00804A),
    accentNegative: Color(0xFFB02222),
    accentInteractive: Color(0xFF1D63B4),
    accentHighlight: Color(0xFFB88A1E),
    dividerColor: Color(0xFFE0E0E0),
  );
}

/// Theme extension that exposes semantic colors to the widget tree.
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final AppColorSet colors;

  const AppThemeExtension(this.colors);

  Color get primaryBackground => colors.primaryBackground;
  Color get surfaceBackground => colors.surfaceBackground;
  Color get primaryText => colors.primaryText;
  Color get secondaryText => colors.secondaryText;
  Color get accentPositive => colors.accentPositive;
  Color get accentNegative => colors.accentNegative;
  Color get accentInteractive => colors.accentInteractive;
  Color get accentHighlight => colors.accentHighlight;
  Color get dividerColor => colors.dividerColor;

  @override
  AppThemeExtension copyWith({AppColorSet? colors}) {
    return AppThemeExtension(colors ?? this.colors);
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    Color lerp(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppThemeExtension(
      AppColorSet(
        primaryBackground: lerp(primaryBackground, other.primaryBackground),
        surfaceBackground: lerp(surfaceBackground, other.surfaceBackground),
        primaryText: lerp(primaryText, other.primaryText),
        secondaryText: lerp(secondaryText, other.secondaryText),
        accentPositive: lerp(accentPositive, other.accentPositive),
        accentNegative: lerp(accentNegative, other.accentNegative),
        accentInteractive: lerp(accentInteractive, other.accentInteractive),
        accentHighlight: lerp(accentHighlight, other.accentHighlight),
        dividerColor: lerp(dividerColor, other.dividerColor),
      ),
    );
  }
}

class AppTypography {
  static TextTheme textTheme(AppColorSet colors) {
    final headlines = GoogleFonts.inter(
      color: colors.primaryText,
      letterSpacing: 0.2,
    );
    final numerics = GoogleFonts.inter(
      color: colors.primaryText,
      letterSpacing: -0.5,
    );
    final body = GoogleFonts.montserrat(
      color: colors.secondaryText,
      letterSpacing: 0.1,
    );

    return TextTheme(
      displayLarge: headlines.copyWith(
        fontSize: 48,
        fontWeight: FontWeight.w600,
      ),
      displayMedium: headlines.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: headlines.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: numerics.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: numerics.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: numerics.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: headlines.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: headlines.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: headlines.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
      bodyLarge: body.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colors.primaryText,
      ),
      bodyMedium: body.copyWith(fontSize: 14),
      bodySmall: body.copyWith(fontSize: 12),
      labelLarge: body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.primaryText,
      ),
      labelMedium: body.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      labelSmall: body.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
    );
  }
}

class AppTheme {
  static ThemeData dark() =>
      _themeFromColors(AppColorSet.dark, brightness: Brightness.dark);

  /// Prepared for future toggling; kept for parity with the dark palette.
  static ThemeData highContrastLight() => _themeFromColors(
    AppColorSet.highContrastLight,
    brightness: Brightness.light,
  );

  static ThemeData _themeFromColors(
    AppColorSet colors, {
    required Brightness brightness,
  }) {
    final textTheme = AppTypography.textTheme(colors);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.primaryBackground,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accentInteractive,
        onPrimary: colors.primaryText,
        secondary: colors.accentHighlight,
        onSecondary: colors.primaryText,
        error: colors.accentNegative,
        onError: colors.primaryText,
        surface: colors.surfaceBackground,
        onSurface: colors.primaryText,
      ),
      textTheme: textTheme,
      iconTheme: IconThemeData(color: colors.primaryText),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: IconThemeData(color: colors.primaryText),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.dividerColor.withOpacity(0.6)),
        ),
      ),
      dividerColor: colors.dividerColor,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surfaceBackground,
        selectedItemColor: colors.accentInteractive,
        unselectedItemColor: colors.secondaryText,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accentInteractive,
          foregroundColor: colors.primaryText,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accentInteractive,
          side: BorderSide(color: colors.accentInteractive),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accentInteractive,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceBackground,
        labelStyle: textTheme.bodyMedium?.copyWith(color: colors.secondaryText),
        hintStyle: textTheme.bodySmall?.copyWith(
          color: colors.secondaryText.withOpacity(0.8),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.accentInteractive),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceBackground,
        selectedColor: colors.accentInteractive.withOpacity(0.2),
        labelStyle: textTheme.bodySmall!,
      ),
      extensions: [AppThemeExtension(colors)],
    );
  }
}
