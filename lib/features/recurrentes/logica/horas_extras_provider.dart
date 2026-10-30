import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../categorias/logica/categorias_provider.dart';
import '../../configuracion/logica/ajustes_provider.dart';
import '../../movimientos/logica/movimientos_provider.dart';
import '../../movimientos/modelo/movimiento.dart';
import '../../movimientos/repositorio/movimiento_repositorio.dart';
import '../repositorio/recurrencia_repositorio.dart';

part 'horas_extras_provider.g.dart';

/// Gestiona la pregunta mensual "¿hiciste horas extras?".
///
/// Devuelve `true` si hay que mostrar el cartel este mes (hay valor de hora
/// extra configurado y el usuario todavía no respondió en el período actual).
@riverpod
class HorasExtrasMes extends _$HorasExtrasMes {
  final RecurrenciaRepositorio _recurRepo = RecurrenciaRepositorio();
  final MovimientoRepositorio _movRepo = MovimientoRepositorio();

  @override
  FutureOr<bool> build() async {
    final valor = (ref.watch(ajustesControladorProvider).valueOrNull?['valorHoraExtra'] as double?) ?? 0.0;
    if (valor <= 0) return false;
    // Se muestra sólo si todavía no respondió este mes (ni "sí" ni "no").
    final aplicadas = await _recurRepo.obtenerAplicadas(_periodo());
    return !aplicadas.contains('horasextras:0');
  }

  /// Valor de la hora extra configurado.
  double get valorHora =>
      (ref.read(ajustesControladorProvider).valueOrNull?['valorHoraExtra'] as double?) ?? 0.0;

  /// Carga las horas extra como un ingreso y marca la pregunta como respondida.
  Future<void> registrarHoras(double horas) async {
    if (horas <= 0) return;
    final valor = valorHora;
    final cats = ref.read(categoriasControladorProvider).valueOrNull ?? [];
    final candidatas = cats.where((c) => c.tipo == 'ingreso' && c.nombre == 'Horas extras');
    final catId = candidatas.isNotEmpty
        ? candidatas.first.id
        : (cats.where((c) => c.tipo == 'ingreso').isNotEmpty
            ? cats.firstWhere((c) => c.tipo == 'ingreso').id
            : null);
    if (catId == null) return;

    final total = horas * valor;
    final horasTxt = horas % 1 == 0 ? horas.toStringAsFixed(0) : horas.toString();
    final movId = await _movRepo.insertar(Movimiento(
      monto: total,
      fecha: DateTime.now(),
      descripcion: '$horasTxt horas extra',
      tipo: 'ingreso',
      categoriaId: catId,
    ));
    await _recurRepo.registrar(tipo: 'horasextras', referenciaId: 0, periodo: _periodo(), movimientoId: movId);
    ref.invalidate(movimientosControladorProvider);
    ref.invalidateSelf();
  }

  /// El usuario respondió "no" este mes: no se vuelve a preguntar.
  Future<void> descartar() async {
    await _recurRepo.registrar(tipo: 'horasextras', referenciaId: 0, periodo: _periodo());
    ref.invalidateSelf();
  }

  /// Marca la pregunta mensual como resuelta sin cargar nada extra. Se usa
  /// cuando el usuario ya cargó las horas extra de este mes por el formulario,
  /// para no contarlas dos veces.
  Future<void> marcarResuelto() async {
    await _recurRepo.registrar(tipo: 'horasextras', referenciaId: 0, periodo: _periodo());
    ref.invalidateSelf();
  }

  String _periodo() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }
}
