import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../modelo/ahorros_acumulados.dart';
import '../repositorio/ahorros_repositorio.dart';

part 'ahorros_provider.g.dart';

/// Provider que gestiona los ahorros acumulados del usuario.
@riverpod
class AhorrosControlador extends _$AhorrosControlador {
  // `final` (no `late final`) para que ref.invalidateSelf() pueda re-ejecutar
  // build() sin lanzar LateInitializationError al reasignar el campo.
  final AhorrosRepositorio _repositorio = AhorrosRepositorio();

  @override
  FutureOr<AhorrosAcumulados> build() async {
    return await _repositorio.obtener();
  }

  /// Actualiza el ahorro previo en ARS y refresca el estado.
  Future<void> actualizarArs(double valor) async {
    await _repositorio.actualizarArs(valor);
    ref.invalidateSelf();
  }

  /// Actualiza el ahorro previo en USD y refresca el estado.
  Future<void> actualizarUsd(double valor) async {
    await _repositorio.actualizarUsd(valor);
    ref.invalidateSelf();
  }
}
