import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Colors that follow the day or night theme.
class SecretPalette extends ThemeExtension<SecretPalette> {
  const SecretPalette({
    required this.night,
    required this.wallpaperBase,
    required this.blobA,
    required this.blobB,
    required this.blobC,
    required this.outgoing,
    required this.incoming,
    required this.outgoingInk,
    required this.incomingInk,
    required this.outgoingMeta,
    required this.incomingMeta,
    required this.composer,
    required this.quiet,
    required this.field,
  });

  final bool night;
  final Color wallpaperBase;
  final Color blobA;
  final Color blobB;
  final Color blobC;
  final Color outgoing;
  final Color incoming;
  final Color outgoingInk;
  final Color incomingInk;
  final Color outgoingMeta;
  final Color incomingMeta;
  final Color composer;
  final Color quiet;
  final Color field;

  /// Opaque column behind chat names. Darker than the thread wallpaper.
  Color get listSurface =>
      night ? const Color(0xFF070C10) : const Color(0xFFB7C2BC);

  static SecretPalette of(BuildContext context) {
    return Theme.of(context).extension<SecretPalette>()!;
  }

  @override
  SecretPalette copyWith({
    bool? night,
    Color? wallpaperBase,
    Color? blobA,
    Color? blobB,
    Color? blobC,
    Color? outgoing,
    Color? incoming,
    Color? outgoingInk,
    Color? incomingInk,
    Color? outgoingMeta,
    Color? incomingMeta,
    Color? composer,
    Color? quiet,
    Color? field,
  }) {
    return SecretPalette(
      night: night ?? this.night,
      wallpaperBase: wallpaperBase ?? this.wallpaperBase,
      blobA: blobA ?? this.blobA,
      blobB: blobB ?? this.blobB,
      blobC: blobC ?? this.blobC,
      outgoing: outgoing ?? this.outgoing,
      incoming: incoming ?? this.incoming,
      outgoingInk: outgoingInk ?? this.outgoingInk,
      incomingInk: incomingInk ?? this.incomingInk,
      outgoingMeta: outgoingMeta ?? this.outgoingMeta,
      incomingMeta: incomingMeta ?? this.incomingMeta,
      composer: composer ?? this.composer,
      quiet: quiet ?? this.quiet,
      field: field ?? this.field,
    );
  }

  @override
  SecretPalette lerp(ThemeExtension<SecretPalette>? other, double t) {
    if (other is! SecretPalette) return this;
    return SecretPalette(
      night: t < 0.5 ? night : other.night,
      wallpaperBase: Color.lerp(wallpaperBase, other.wallpaperBase, t)!,
      blobA: Color.lerp(blobA, other.blobA, t)!,
      blobB: Color.lerp(blobB, other.blobB, t)!,
      blobC: Color.lerp(blobC, other.blobC, t)!,
      outgoing: Color.lerp(outgoing, other.outgoing, t)!,
      incoming: Color.lerp(incoming, other.incoming, t)!,
      outgoingInk: Color.lerp(outgoingInk, other.outgoingInk, t)!,
      incomingInk: Color.lerp(incomingInk, other.incomingInk, t)!,
      outgoingMeta: Color.lerp(outgoingMeta, other.outgoingMeta, t)!,
      incomingMeta: Color.lerp(incomingMeta, other.incomingMeta, t)!,
      composer: Color.lerp(composer, other.composer, t)!,
      quiet: Color.lerp(quiet, other.quiet, t)!,
      field: Color.lerp(field, other.field, t)!,
    );
  }
}

const _dayPalette = SecretPalette(
  night: false,
  wallpaperBase: Color(0xFFD5E6DC),
  blobA: Color(0xFFF4CDBB),
  blobB: Color(0xFF8FC4AE),
  blobC: Color(0xFFF0D98A),
  outgoing: Color(0xFFD8F3E6),
  incoming: Color(0xFFFFFCF8),
  outgoingInk: Color(0xFF14352C),
  incomingInk: Color(0xFF1C2421),
  outgoingMeta: Color(0xFF3E6B5C),
  incomingMeta: Color(0xFF6E7A74),
  composer: Color(0xFFF7FAF8),
  quiet: Color(0xFF6E7A74),
  field: Color(0xFFFFFFFF),
);

const _nightPalette = SecretPalette(
  night: true,
  wallpaperBase: Color(0xFF0E171E),
  blobA: Color(0xFF1C6B5C),
  blobB: Color(0xFF31457A),
  blobC: Color(0xFF6B4638),
  outgoing: Color(0xFF1C4E41),
  incoming: Color(0xFF24313A),
  outgoingInk: Color(0xFFE7F6EF),
  incomingInk: Color(0xFFE6EEEA),
  outgoingMeta: Color(0xFF9BB8AD),
  incomingMeta: Color(0xFF8A9892),
  composer: Color(0xFF162028),
  quiet: Color(0xFF8A9892),
  field: Color(0xFF1C2830),
);

ThemeData secretTheme() => _theme(Brightness.light, _dayPalette);

ThemeData secretDarkTheme() => _theme(Brightness.dark, _nightPalette);

ThemeData _theme(Brightness brightness, SecretPalette palette) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: brightness == Brightness.dark
            ? const Color(0xFF8FCBB8)
            : const Color(0xFF1F6B57),
        brightness: brightness,
        surface: brightness == Brightness.dark
            ? const Color(0xFF121A20)
            : const Color(0xFFF3F6F4),
      ).copyWith(
        primary: brightness == Brightness.dark
            ? const Color(0xFF8FCBB8)
            : const Color(0xFF1F6B57),
        onPrimary: brightness == Brightness.dark
            ? const Color(0xFF10211B)
            : Colors.white,
        surface: brightness == Brightness.dark
            ? const Color(0xFF121A20)
            : const Color(0xFFF3F6F4),
        onSurface: brightness == Brightness.dark
            ? const Color(0xFFE6EEEA)
            : const Color(0xFF1C2421),
      );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    dividerColor: palette.quiet.withValues(alpha: 0.28),
    extensions: [palette],
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(color: palette.field, elevation: 0),
    dialogTheme: DialogThemeData(backgroundColor: palette.composer),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    listTileTheme: ListTileThemeData(
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: TextStyle(color: palette.quiet, fontSize: 13),
    ),
  );
}

class ThemeModeController extends Notifier<ThemeMode> {
  static const storageKey = 'appearance';

  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.light;
  }

  void _restore() {
    SharedPreferences.getInstance().then((prefs) {
      if (!ref.mounted) return;
      final stored = prefs.getString(storageKey);
      final next = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
      if (next != state) state = next;
    });
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      next == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
