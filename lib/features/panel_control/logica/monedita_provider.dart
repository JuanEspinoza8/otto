import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'servicio_monedita.dart';
import 'servicio_ia_monedita.dart';
import '../../movimientos/modelo/movimiento.dart';
import '../../movimientos/repositorio/movimiento_repositorio.dart';
import '../../movimientos/logica/movimientos_provider.dart';
import '../../categorias/modelo/categoria.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../../recurrentes/modelo/gasto_fijo.dart';
import '../../recurrentes/logica/gastos_fijos_provider.dart';
import '../../recurrentes/repositorio/gasto_fijo_repositorio.dart';
import '../../recurrentes/repositorio/recurrencia_repositorio.dart';

part 'monedita_provider.g.dart';

/// Estados posibles del chat de Otto.
enum EstadoMonedita { inactivo, procesando, sugerencia, error }

/// Una propuesta de Otto: la sugerencia interpretada + info de conciliación
/// con un gasto fijo (si el gasto coincide con uno cargado).
class PropuestaOtto {
  final SugerenciaMonedita sugerencia;
  final GastoFijo? fijo;
  final bool yaAplicadoEsteMes;
  final int? movimientoExistenteId;

  const PropuestaOtto({
    required this.sugerencia,
    this.fijo,
    this.yaAplicadoEsteMes = false,
    this.movimientoExistenteId,
  });

  /// El monto dictado difiere del que tiene cargado el fijo.
  bool get difiereDelFijo =>
      fijo != null && (fijo!.monto - sugerencia.monto).abs() > 0.5;
}

/// Estado completo del chat de Otto.
class MoneditaEstado {
  final EstadoMonedita estado;
  final List<PropuestaOtto> propuestas;
  final String? mensajeError;

  const MoneditaEstado({
    this.estado = EstadoMonedita.inactivo,
    this.propuestas = const [],
    this.mensajeError,
  });
}

/// Provider que gestiona el chat inteligente de Otto.
@riverpod
class MoneditaControlador extends _$MoneditaControlador {
  final MovimientoRepositorio _movRepo = MovimientoRepositorio();
  final GastoFijoRepositorio _fijoRepo = GastoFijoRepositorio();
  final RecurrenciaRepositorio _recurRepo = RecurrenciaRepositorio();

  @override
  MoneditaEstado build() => const MoneditaEstado();

  /// Interpreta el mensaje (puede tener varios movimientos) y arma propuestas.
  Future<void> procesarMensaje(String texto) async {
    state = const MoneditaEstado(estado: EstadoMonedita.procesando);

    final categorias = ref.read(categoriasControladorProvider).valueOrNull ?? [];

    // 1) IA (Pollinations). 2) Fallback local multi-movimiento.
    var sugerencias = await ServicioIaMonedita.interpretar(texto, categorias);
    if (sugerencias.isEmpty) {
      sugerencias = ServicioMonedita.interpretarMulti(texto, categorias);
    }

    if (sugerencias.isEmpty) {
      state = const MoneditaEstado(
        estado: EstadoMonedita.error,
        mensajeError: 'No pude entender el mensaje. Probá con algo como "gasté 5000 en el super".',
      );
      return;
    }

    // 3) Conciliación con gastos fijos.
    final fijos = ref.read(gastosFijosControladorProvider).valueOrNull ?? [];
    final periodo = _periodoActual();
    final propuestas = <PropuestaOtto>[];

    for (final s in sugerencias) {
      GastoFijo? fijo;
      bool aplicado = false;
      int? movId;
      if (s.tipo == 'gasto') {
        fijo = _matchFijo(s, fijos);
        if (fijo != null) {
          movId = await _recurRepo.obtenerMovimientoId(
              tipo: 'fijo', referenciaId: fijo.id!, periodo: periodo);
          aplicado = movId != null;
        }
      }
      propuestas.add(PropuestaOtto(
        sugerencia: s,
        fijo: fijo,
        yaAplicadoEsteMes: aplicado,
        movimientoExistenteId: movId,
      ));
    }

    state = MoneditaEstado(estado: EstadoMonedita.sugerencia, propuestas: propuestas);
  }

  GastoFijo? _matchFijo(SugerenciaMonedita s, List<GastoFijo> fijos) {
    final desc = s.descripcion.toLowerCase();
    for (final f in fijos) {
      if (!f.activo) continue;
      if (f.nombre.isNotEmpty && desc.contains(f.nombre.toLowerCase())) return f;
    }
    // Como segundo criterio, mismo id de categoría.
    if (s.categoriaId != null) {
      for (final f in fijos) {
        if (f.activo && f.categoriaId == s.categoriaId) return f;
      }
    }
    return null;
  }

  /// Confirma una propuesta creando (o corrigiendo) el movimiento.
  /// [actualizarFijo]: si difiere del fijo, actualiza el monto del fijo.
  /// [categoriaIdOverride]: para cambiar la categoría sugerida.
  Future<void> confirmar(
    PropuestaOtto p, {
    bool actualizarFijo = true,
    int? categoriaIdOverride,
  }) async {
    final categorias = ref.read(categoriasControladorProvider).valueOrNull ?? [];
    final s = p.sugerencia;

    int? categoriaId = categoriaIdOverride ?? s.categoriaId;
    categoriaId ??= _categoriaDefault(categorias, s.tipo);
    if (categoriaId == null) {
      _quitar(p);
      return;
    }

    final periodo = _periodoActual();

    if (p.fijo != null && p.yaAplicadoEsteMes && p.movimientoExistenteId != null) {
      // El fijo ya se descontó este mes: corregimos ese movimiento en vez de
      // crear uno nuevo (evita duplicar).
      await _movRepo.actualizar(Movimiento(
        id: p.movimientoExistenteId,
        monto: s.monto,
        fecha: DateTime.now(),
        descripcion: s.descripcion,
        tipo: 'gasto',
        categoriaId: categoriaId,
      ));
    } else {
      final movId = await _movRepo.insertar(Movimiento(
        monto: s.monto,
        fecha: DateTime.now(),
        descripcion: s.descripcion,
        tipo: s.tipo,
        categoriaId: categoriaId,
      ));
      // Si era un fijo no aplicado aún este mes, lo marcamos aplicado para que
      // el recordatorio de "pendientes del mes" no lo vuelva a descontar.
      if (p.fijo != null) {
        await _recurRepo.registrar(
            tipo: 'fijo', referenciaId: p.fijo!.id!, periodo: periodo, movimientoId: movId);
      }
    }

    // Corrección del monto del fijo a futuro.
    if (p.fijo != null && actualizarFijo && p.difiereDelFijo) {
      await _fijoRepo.actualizar(p.fijo!.copiaCon(monto: s.monto));
      ref.invalidate(gastosFijosControladorProvider);
    }

    ref.invalidate(movimientosControladorProvider);
    _quitar(p);
  }

  void cancelar(PropuestaOtto p) => _quitar(p);

  void limpiar() => state = const MoneditaEstado();

  void _quitar(PropuestaOtto p) {
    final restantes = state.propuestas.where((x) => x != p).toList();
    state = MoneditaEstado(
      estado: restantes.isEmpty ? EstadoMonedita.inactivo : EstadoMonedita.sugerencia,
      propuestas: restantes,
    );
  }

  String _periodoActual() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  int? _categoriaDefault(List<Categoria> cats, String tipo) {
    final clave = tipo == 'gasto' ? 'otros' : 'sueldo';
    for (final c in cats) {
      if (c.tipo == tipo && c.nombre.toLowerCase().contains(clave)) return c.id;
    }
    final delTipo = cats.where((c) => c.tipo == tipo);
    return delTipo.isNotEmpty ? delTipo.first.id : null;
  }
}
