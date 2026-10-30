import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'tema_provider.g.dart';

/// Controlador del modo de tema (claro/oscuro) persistido en disco.
///
/// Por defecto la app arranca en modo oscuro (diseño de referencia).
@Riverpod(keepAlive: true)
class TemaControlador extends _$TemaControlador {
  static const _clave = 'modoOscuro';

  @override
  ThemeMode build() {
    // Se inicializa de forma síncrona con el valor por defecto y se corrige
    // al leer las preferencias para evitar parpadeos.
    _cargarPreferencia();
    return ThemeMode.dark;
  }

  Future<void> _cargarPreferencia() async {
    final prefs = await SharedPreferences.getInstance();
    final oscuro = prefs.getBool(_clave) ?? true;
    final modo = oscuro ? ThemeMode.dark : ThemeMode.light;
    if (modo != state) state = modo;
  }

  /// Alterna entre claro y oscuro y persiste la elección.
  Future<void> alternar() async {
    final nuevoOscuro = state != ThemeMode.dark;
    state = nuevoOscuro ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clave, nuevoOscuro);
  }
}
