import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'autenticador.g.dart';

/// Huella, rostro o el bloqueo de pantalla del teléfono. Es una interfaz
/// para poder reemplazarla en los tests.
abstract class Autenticador {
  /// Si el teléfono tiene algún método de bloqueo configurado.
  Future<bool> disponible();

  /// Pide autenticarse. Cualquier error cuenta como "no autenticado".
  Future<bool> autenticar(String motivo);

  /// Oculta la app en la vista de recientes y bloquea capturas.
  Future<void> protegerPantalla(bool activar);
}

class AutenticadorDispositivo implements Autenticador {
  final _auth = LocalAuthentication();
  static const _canal = MethodChannel('otto/seguridad');

  @override
  Future<bool> disponible() async {
    try {
      return await _auth.isDeviceSupported() || await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> autenticar(String motivo) async {
    try {
      return await _auth.authenticate(
        localizedReason: motivo,
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> protegerPantalla(bool activar) async {
    try {
      await _canal.invokeMethod('protegerPantalla', activar);
    } on MissingPluginException {
      // Fuera de Android (tests) no hay ventana que proteger.
    }
  }
}

@Riverpod(keepAlive: true)
Autenticador autenticador(Ref ref) => AutenticadorDispositivo();
