import 'package:flutter/material.dart';

/// Colores semánticos dependientes del tema, expuestos como [ThemeExtension].
///
/// Al leerse vía `Theme.of(context)` (a través de [BuildContext.colores]),
/// incluso los widgets `const` se reconstruyen cuando cambia el tema, porque
/// registran una dependencia del InheritedWidget del tema. Esto evita el bug
/// de colores "pegados" que tenía el enfoque de flag global.
class ColoresApp extends ThemeExtension<ColoresApp> {
  final Color fondo;
  final Color superficie;
  final Color superficieAlta;
  final Color borde;
  final Color textoPrimario;
  final Color textoSecundario;

  const ColoresApp({
    required this.fondo,
    required this.superficie,
    required this.superficieAlta,
    required this.borde,
    required this.textoPrimario,
    required this.textoSecundario,
  });

  static const ColoresApp oscuro = ColoresApp(
    fondo: Color(0xFF0A0A0A),
    superficie: Color(0xFF1A1A1C),
    superficieAlta: Color(0xFF2A2A2C),
    borde: Color(0xFF2C2C2E),
    textoPrimario: Color(0xFFF5F5F5),
    textoSecundario: Color(0xFF8E8E93),
  );

  static const ColoresApp claro = ColoresApp(
    fondo: Color(0xFFF2F2F7),
    superficie: Colors.white,
    superficieAlta: Color(0xFFEAEAEF),
    borde: Color(0xFFE2E2E7),
    textoPrimario: Color(0xFF1A1A1A),
    textoSecundario: Color(0xFF6C6C70),
  );

  @override
  ColoresApp copyWith({
    Color? fondo,
    Color? superficie,
    Color? superficieAlta,
    Color? borde,
    Color? textoPrimario,
    Color? textoSecundario,
  }) {
    return ColoresApp(
      fondo: fondo ?? this.fondo,
      superficie: superficie ?? this.superficie,
      superficieAlta: superficieAlta ?? this.superficieAlta,
      borde: borde ?? this.borde,
      textoPrimario: textoPrimario ?? this.textoPrimario,
      textoSecundario: textoSecundario ?? this.textoSecundario,
    );
  }

  @override
  ColoresApp lerp(ThemeExtension<ColoresApp>? other, double t) {
    if (other is! ColoresApp) return this;
    return ColoresApp(
      fondo: Color.lerp(fondo, other.fondo, t)!,
      superficie: Color.lerp(superficie, other.superficie, t)!,
      superficieAlta: Color.lerp(superficieAlta, other.superficieAlta, t)!,
      borde: Color.lerp(borde, other.borde, t)!,
      textoPrimario: Color.lerp(textoPrimario, other.textoPrimario, t)!,
      textoSecundario: Color.lerp(textoSecundario, other.textoSecundario, t)!,
    );
  }
}

/// Acceso corto a los colores semánticos del tema activo.
extension ColoresContext on BuildContext {
  ColoresApp get colores =>
      Theme.of(this).extension<ColoresApp>() ?? ColoresApp.oscuro;
}

/// Tema centralizado de la aplicación con soporte claro/oscuro.
class TemaApp {
  // --- Colores de marca (idénticos en ambos temas) ---

  /// Verde de acento principal (marca Otto, ingresos, acciones).
  static const Color verde = Color(0xFF22C55E);

  /// Rojo para gastos y acciones destructivas.
  static const Color rojo = Color(0xFFEF4444);

  /// Azul para ahorros y balances.
  static const Color azul = Color(0xFF3B82F6);

  /// Alerta de presupuesto (80%).
  static const Color amarillo = Color(0xFFF59E0B);

  /// Color oscuro fijo para elementos que deben verse igual en ambos temas
  /// (ej. el visor de monto del formulario de registro).
  static const Color superficieFijaOscura = Color(0xFF1A1A1C);

  static ThemeData obtenerTema(Brightness brillo) {
    final ColoresApp colores =
        brillo == Brightness.dark ? ColoresApp.oscuro : ColoresApp.claro;

    final esquema = ColorScheme.fromSeed(
      seedColor: verde,
      brightness: brillo,
    ).copyWith(
      surface: colores.superficie,
      primary: verde,
      error: rojo,
      onSurface: colores.textoPrimario,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brillo,
      colorScheme: esquema,
      extensions: <ThemeExtension<dynamic>>[colores],
      scaffoldBackgroundColor: colores.fondo,
      canvasColor: colores.fondo,
      dividerColor: colores.borde,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colores.textoPrimario,
        centerTitle: true,
      ),
      cardColor: colores.superficie,
      dialogTheme: DialogThemeData(backgroundColor: colores.superficie),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: colores.superficie),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colores.superficieAlta,
        hintStyle: TextStyle(color: colores.textoSecundario),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colores.superficieAlta,
        contentTextStyle: TextStyle(color: colores.textoPrimario),
      ),
      textTheme: const TextTheme().apply(
        bodyColor: colores.textoPrimario,
        displayColor: colores.textoPrimario,
      ),
    );
  }

  static ThemeData obtenerTemaOscuro() => obtenerTema(Brightness.dark);
  static ThemeData obtenerTemaClaro() => obtenerTema(Brightness.light);
}
