import 'package:flutter/material.dart';

import '../libro/servicio_libro.dart';
import '../tema/tema_app.dart';

/// Corre una escritura y avisa el resultado con un SnackBar recién cuando
/// terminó. Devuelve true si se guardó.
///
/// Los [ErrorLibro] se muestran tal cual (son mensajes para el usuario); el
/// resto, con un mensaje genérico.
Future<bool> ejecutarConAviso(
  BuildContext context,
  Future<void> Function() accion, {
  String? exito,
}) async {
  final mensajero = ScaffoldMessenger.of(context);
  try {
    await accion();
    if (exito != null) {
      mensajero.showSnackBar(SnackBar(
        content: Text(exito, style: const TextStyle(color: Colors.white)),
        backgroundColor: TemaApp.verde,
      ));
    }
    return true;
  } on ErrorLibro catch (e) {
    mensajero.showSnackBar(SnackBar(content: Text(e.mensaje), backgroundColor: TemaApp.rojo));
    return false;
  } catch (_) {
    mensajero.showSnackBar(const SnackBar(content: Text('No se pudo guardar. Probá de nuevo.'), backgroundColor: TemaApp.rojo));
    return false;
  }
}
