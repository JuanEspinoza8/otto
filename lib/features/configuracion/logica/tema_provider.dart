import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/preferencias.dart';

part 'tema_provider.g.dart';

/// Modo claro u oscuro, guardado en las preferencias (oscuro por defecto).
@Riverpod(keepAlive: true)
class TemaControlador extends _$TemaControlador {
  static const _clave = 'modoOscuro';

  @override
  ThemeMode build() =>
      (ref.watch(preferenciasProvider).getBool(_clave) ?? true) ? ThemeMode.dark : ThemeMode.light;

  Future<void> alternar() async {
    final oscuro = state != ThemeMode.dark;
    state = oscuro ? ThemeMode.dark : ThemeMode.light;
    await ref.read(preferenciasProvider).setBool(_clave, oscuro);
  }
}
