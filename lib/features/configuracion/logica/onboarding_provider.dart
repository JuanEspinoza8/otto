import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/libro/libro_providers.dart';
import '../../../core/preferencias.dart';
import '../../recurrentes/logica/servicio_planes.dart';
import '../repositorio/ajustes_repositorio.dart';

part 'onboarding_provider.g.dart';

/// Si el usuario ya completó la configuración inicial.
@Riverpod(keepAlive: true)
class OnboardingControlador extends _$OnboardingControlador {
  static const _kCompleto = 'onboardingCompleto';

  @override
  bool build() => ref.watch(preferenciasProvider).getBool(_kCompleto) ?? false;

  /// Guarda el nombre, crea el plan del sueldo y el valor de la hora extra.
  Future<void> completarOnboarding({
    required String nombre,
    required Dinero salarioMensual,
    required Dinero valorHoraExtra,
  }) async {
    await escribirEnTransaccion(ref, (txn) async {
      await ServicioPlanes(txn).fijarSueldo(salarioMensual, hoy: DateTime.now());
      if (valorHoraExtra.esPositivo) await AjustesRepositorio(txn).fijarValorHoraExtra(valorHoraExtra);
    });
    final prefs = ref.read(preferenciasProvider);
    await prefs.setString('nombreUsuario', nombre);
    await prefs.setBool(_kCompleto, true);
    state = true;
  }
}
