import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/libro/consultas_libro.dart';
import '../../../core/libro/libro_providers.dart';
import '../../../core/libro/modelo/movimiento.dart';
import '../../../core/utilidades/fechas.dart';
import 'mes_seleccionado_provider.dart';

part 'movimientos_provider.g.dart';

const int _tamanioPagina = 30;

/// Movimientos del mes seleccionado, de a páginas de 30.
@riverpod
class MovimientosControlador extends _$MovimientosControlador {
  bool _hayMas = true;
  bool _cargando = false;

  bool get hayMasDatos => _hayMas;

  @override
  Future<List<Movimiento>> build() async {
    final mes = Periodo.de(ref.watch(mesSeleccionadoProvider));
    final pagina = await (await consultasLibro(ref)).movimientos(mes: mes, limite: _tamanioPagina);
    _hayMas = pagina.length == _tamanioPagina;
    return pagina;
  }

  Future<void> cargarMas() async {
    final actuales = state.valueOrNull;
    if (!_hayMas || _cargando || actuales == null) return;
    _cargando = true;
    try {
      final mes = Periodo.de(ref.read(mesSeleccionadoProvider));
      final db = await ref.read(baseDatosProvider.future);
      final pagina = await ConsultasLibro(db).movimientos(
        mes: mes,
        limite: _tamanioPagina,
        desplazamiento: actuales.length,
      );
      _hayMas = pagina.length == _tamanioPagina;
      state = AsyncData([...actuales, ...pagina]);
    } finally {
      _cargando = false;
    }
  }

  Future<int> registrar({
    required TipoMovimiento tipo,
    required Dinero monto,
    required int categoriaId,
    required DateTime fecha,
    String? descripcion,
  }) =>
      escribirEnLibro(ref, (l) => l.registrar(
            tipo: tipo,
            monto: monto,
            categoriaId: categoriaId,
            fecha: fecha,
            descripcion: descripcion,
          ));

  Future<void> editar(Movimiento m, {required Dinero monto, required int categoriaId, required DateTime fecha, String? descripcion}) =>
      escribirEnLibro(ref, (l) => l.editar(m.id!, monto: monto, categoriaId: categoriaId, fecha: fecha, descripcion: descripcion));

  Future<void> eliminar(int id) => escribirEnLibro(ref, (l) => l.eliminar(id));
}

/// Criterios de "Todos los movimientos".
class BusquedaMovimientos {
  const BusquedaMovimientos({this.filtro = FiltroMovimientos.todos, this.texto = ''});
  final FiltroMovimientos filtro;
  final String texto;
}

@riverpod
class CriteriosBusqueda extends _$CriteriosBusqueda {
  @override
  BusquedaMovimientos build() => const BusquedaMovimientos();

  void filtrar(FiltroMovimientos filtro) => state = BusquedaMovimientos(filtro: filtro, texto: state.texto);
  void buscar(String texto) => state = BusquedaMovimientos(filtro: state.filtro, texto: texto);
}

/// Movimientos del mes seleccionado con filtro y búsqueda resueltos en SQL
/// (no sobre la página ya cargada), de a páginas.
@riverpod
class MovimientosBuscados extends _$MovimientosBuscados {
  bool _hayMas = true;
  bool _cargando = false;

  bool get hayMasDatos => _hayMas;

  @override
  Future<List<Movimiento>> build() async {
    final criterios = ref.watch(criteriosBusquedaProvider);
    final mes = Periodo.de(ref.watch(mesSeleccionadoProvider));
    final pagina = await (await consultasLibro(ref))
        .movimientos(mes: mes, filtro: criterios.filtro, busqueda: criterios.texto, limite: _tamanioPagina);
    _hayMas = pagina.length == _tamanioPagina;
    return pagina;
  }

  Future<void> cargarMas() async {
    final actuales = state.valueOrNull;
    if (!_hayMas || _cargando || actuales == null) return;
    _cargando = true;
    try {
      final criterios = ref.read(criteriosBusquedaProvider);
      final db = await ref.read(baseDatosProvider.future);
      final pagina = await ConsultasLibro(db).movimientos(
        mes: Periodo.de(ref.read(mesSeleccionadoProvider)),
        filtro: criterios.filtro,
        busqueda: criterios.texto,
        limite: _tamanioPagina,
        desplazamiento: actuales.length,
      );
      _hayMas = pagina.length == _tamanioPagina;
      state = AsyncData([...actuales, ...pagina]);
    } finally {
      _cargando = false;
    }
  }
}
