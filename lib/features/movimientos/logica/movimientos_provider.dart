import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../modelo/movimiento.dart';
import '../repositorio/movimiento_repositorio.dart';
import 'mes_seleccionado_provider.dart';

part 'movimientos_provider.g.dart';

@riverpod
class MovimientosControlador extends _$MovimientosControlador {
  // `final` (no `late final`): build() se re-ejecuta en cada invalidateSelf()
  // y reasignar un `late final` lanzaría LateInitializationError.
  final MovimientoRepositorio _repositorio = MovimientoRepositorio();
  int _desplazamiento = 0;
  final int _limite = 30;
  bool _hayMasDatos = true;

  bool get hayMasDatos => _hayMasDatos;

  @override
  FutureOr<List<Movimiento>> build() async {
    _desplazamiento = 0;
    _hayMasDatos = true;
    return await _cargarPaginaInicial();
  }

  Future<List<Movimiento>> _cargarPaginaInicial() async {
    final mesActual = ref.watch(mesSeleccionadoProvider);
    final movimientos = await _repositorio.obtenerPaginados(limite: _limite, desplazamiento: _desplazamiento, mes: mesActual);
    if (movimientos.length < _limite) {
      _hayMasDatos = false;
    }
    return movimientos;
  }

  Future<void> cargarMas() async {
    if (!_hayMasDatos || state.isLoading) return;

    _desplazamiento += _limite;
    final mesActual = ref.read(mesSeleccionadoProvider);
    final nuevosMovimientos = await _repositorio.obtenerPaginados(limite: _limite, desplazamiento: _desplazamiento, mes: mesActual);

    if (nuevosMovimientos.length < _limite) {
      _hayMasDatos = false;
    }

    if (state.hasValue) {
      state = AsyncValue.data([...state.value!, ...nuevosMovimientos]);
    }
  }

  Future<void> agregarMovimiento(Movimiento movimiento) async {
    await _repositorio.insertar(movimiento);
    ref.invalidateSelf();
  }

  Future<void> actualizarMovimiento(Movimiento movimiento) async {
    await _repositorio.actualizar(movimiento);
    ref.invalidateSelf();
  }

  Future<void> eliminarMovimiento(int id) async {
    await _repositorio.eliminar(id);
    ref.invalidateSelf();
  }
}

@riverpod
class FiltroMovimientos extends _$FiltroMovimientos {
  @override
  String build() => 'todos'; // 'todos', 'ingreso', 'gasto'

  void cambiarFiltro(String filtro) {
    state = filtro;
  }
}

@riverpod
List<Movimiento> movimientosFiltrados(MovimientosFiltradosRef ref) {
  final filtro = ref.watch(filtroMovimientosProvider);
  final movimientosAsync = ref.watch(movimientosControladorProvider);

  final movimientos = movimientosAsync.valueOrNull ?? [];

  if (filtro == 'todos') {
    return movimientos;
  }
  return movimientos.where((m) => m.tipo == filtro).toList();
}
