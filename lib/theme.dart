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
      night ? const Color(0xFF070B10) : const Color(0xFFC3D0DC);

  /// Bright row used only while extra encryption is on for that chat.
  Color extraRow({required bool selected}) {
    if (night) {
      return selected ? const Color(0xFF3B96DC) : const Color(0xFF2176B8);
    }
    return selected ? const Color(0xFF4EAEF5) : const Color(0xFF7EC8FF);
  }

  /// Thread wash while extra encryption is on. Brighter than [wallpaperBase].
  Color get lockedWallpaper =>
      night ? const Color(0xFF1E5688) : const Color(0xFFB7E0FF);

  Color get lockedComposer =>
      night ? const Color(0xFF163E64) : const Color(0xFFD7EEFF);

  Color get lockedField =>
      night ? const Color(0xFF1A4E7C) : const Color(0xFFF3F9FF);

  Color get lockedInk =>
      night ? const Color(0xFFF4FAFF) : const Color(0xFF14558C);

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
  wallpaperBase: Color(0xFFD4E4F4),
  blobA: Color(0xFF7EB6E8),
  blobB: Color(0xFF9AA8B5),
  blobC: Color(0xFF4C8DCE),
  outgoing: Color(0xFFD6EBFA),
  incoming: Color(0xFFF7F9FB),
  outgoingInk: Color(0xFF12202C),
  incomingInk: Color(0xFF1A242E),
  outgoingMeta: Color(0xFF4E6E88),
  incomingMeta: Color(0xFF7A8794),
  composer: Color(0xFFF3F6F9),
  quiet: Color(0xFF7A8794),
  field: Color(0xFFFFFFFF),
);

const _nightPalette = SecretPalette(
  night: true,
  wallpaperBase: Color(0xFF0E1621),
  blobA: Color(0xFF2B5278),
  blobB: Color(0xFF3D4F61),
  blobC: Color(0xFF1B3A56),
  outgoing: Color(0xFF2B5278),
  incoming: Color(0xFF182533),
  outgoingInk: Color(0xFFE8F1F8),
  incomingInk: Color(0xFFE6EEF4),
  outgoingMeta: Color(0xFF8EABC4),
  incomingMeta: Color(0xFF8A97A3),
  composer: Color(0xFF17212B),
  quiet: Color(0xFF8A97A3),
  field: Color(0xFF1C2733),
);

ThemeData secretTheme() => _theme(Brightness.light, _dayPalette);

ThemeData secretDarkTheme() => _theme(Brightness.dark, _nightPalette);

ThemeData _theme(Brightness brightness, SecretPalette palette) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: brightness == Brightness.dark
            ? const Color(0xFF6AB2F2)
            : const Color(0xFF3390EC),
        brightness: brightness,
        surface: brightness == Brightness.dark
            ? const Color(0xFF17212B)
            : const Color(0xFFE7EEF4),
      ).copyWith(
        primary: brightness == Brightness.dark
            ? const Color(0xFF6AB2F2)
            : const Color(0xFF3390EC),
        onPrimary: brightness == Brightness.dark
            ? const Color(0xFF0B1A28)
            : Colors.white,
        secondary: brightness == Brightness.dark
            ? const Color(0xFF8AA0B4)
            : const Color(0xFF5C7386),
        surface: brightness == Brightness.dark
            ? const Color(0xFF17212B)
            : const Color(0xFFE7EEF4),
        onSurface: brightness == Brightness.dark
            ? const Color(0xFFE6EEF4)
            : const Color(0xFF1A242E),
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
