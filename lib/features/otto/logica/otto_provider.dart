import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/libro/libro_providers.dart';
import '../../../core/libro/modelo/movimiento.dart';
import '../../../core/libro/servicio_libro.dart';
import '../../../core/utilidades/fechas.dart';
import '../../../core/utilidades/texto.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../../categorias/modelo/categoria.dart';
import '../../configuracion/logica/ajustes_provider.dart';
import '../../recurrentes/logica/horas_extras_provider.dart';
import '../../recurrentes/logica/planes_provider.dart';
import '../../recurrentes/logica/servicio_planes.dart';
import '../../recurrentes/modelo/plan.dart';
import '../../recurrentes/repositorio/avisos_repositorio.dart';
import 'interprete_ia.dart';
import 'parser_local.dart';
import 'sugerencia_otto.dart';

part 'otto_provider.g.dart';

enum EstadoOtto { inactivo, procesando, sugerencia, error }

/// Un movimiento propuesto por Otto, a confirmar por el usuario.
class PropuestaOtto {
  const PropuestaOtto({required this.id, required this.sugerencia, this.fijo, this.fijoAplicadoEsteMes = false});

  /// Identifica la tarjeta en la lista (para que el estado de cada una no
  /// pase a la siguiente al confirmar).
  final int id;
  final SugerenciaOtto sugerencia;

  /// Gasto fijo con exactamente el mismo nombre que la descripción.
  final Plan? fijo;
  final bool fijoAplicadoEsteMes;

  bool get difiereDelFijo => fijo != null && fijo!.monto != sugerencia.monto;
}

class EstadoChatOtto {
  const EstadoChatOtto({this.estado = EstadoOtto.inactivo, this.propuestas = const [], this.mensajeError});
  final EstadoOtto estado;
  final List<PropuestaOtto> propuestas;
  final String? mensajeError;
}

/// Chat "Decile a Otto": interpreta el mensaje (con IA si está activa, si no
/// con el parser local) y registra cada propuesta con el mismo servicio que el
/// formulario.
@riverpod
class OttoControlador extends _$OttoControlador {
  int _siguienteId = 0;

  @override
  EstadoChatOtto build() => const EstadoChatOtto();

  Future<void> procesarMensaje(String texto) async {
    if (texto.trim().isEmpty || state.estado == EstadoOtto.procesando) return;
    state = const EstadoChatOtto(estado: EstadoOtto.procesando);

    final categorias = await ref.read(categoriasControladorProvider.future);
    final iaActiva = (await ref.read(ajustesControladorProvider.future)).iaActiva;
    var sugerencias = iaActiva ? await InterpreteIa.interpretar(texto, categorias) : <SugerenciaOtto>[];
    if (sugerencias.isEmpty) sugerencias = ParserLocal.interpretar(texto, categorias);

    if (sugerencias.isEmpty) {
      state = const EstadoChatOtto(
        estado: EstadoOtto.error,
        mensajeError: 'No pude entender el mensaje. Probá con algo como "gasté 5000 en el super".',
      );
      return;
    }

    final actual = Periodo.de(DateTime.now());
    final fijos = (await ref.read(planesControladorProvider.future))
        .where((p) => p.tipo == TipoPlan.fijo && p.activo)
        .toList();
    state = EstadoChatOtto(
      estado: EstadoOtto.sugerencia,
      propuestas: [
        for (final s in sugerencias) _propuesta(s, fijos, actual),
      ],
    );
  }

  /// Solo concilia con un fijo si el nombre coincide exacto ("Gas" no es
  /// "gaseosa", y "cine" no es Netflix aunque sean de la misma categoría).
  PropuestaOtto _propuesta(SugerenciaOtto s, List<Plan> fijos, Periodo actual) {
    final fijo = s.esGasto
        ? fijos.where((f) => normalizar(f.nombre) == normalizar(s.descripcion)).firstOrNull
        : null;
    return PropuestaOtto(
      id: _siguienteId++,
      sugerencia: s,
      fijo: fijo,
      fijoAplicadoEsteMes: fijo?.periodosAplicados.contains(actual) ?? false,
    );
  }

  /// Registra la propuesta con fecha de hoy.
  ///
  /// [conciliarConFijo] la enlaza con el mes actual del fijo (así no vuelve a
  /// aparecer como pendiente); nunca reemplaza un movimiento existente.
  /// [actualizarMontoFijo] cambia el monto del fijo para los próximos meses.
  Future<void> confirmar(
    PropuestaOtto p, {
    int? categoriaId,
    bool conciliarConFijo = false,
    bool actualizarMontoFijo = false,
  }) async {
    final s = p.sugerencia;
    final categorias = await ref.read(categoriasControladorProvider.future);
    final categoria = _categoria(categorias, categoriaId ?? s.categoriaId, s.tipo);
    if (categoria == null) throw const ErrorLibro('Elegí una categoría');
    final hoy = DateTime.now();

    await escribirEnTransaccion(ref, (txn) async {
      // Misma regla que el formulario: con la categoría de horas extra y
      // horas en el mensaje, el ingreso es horas × valor de la hora.
      if (categoria.nombre == categoriaHorasExtras && s.horas != null) {
        await registrarHorasExtras(txn, horas: s.horas!, fecha: hoy, descripcion: s.descripcion, origen: OrigenMovimiento.ia);
        return;
      }
      final movimientoId = await ServicioLibro(txn).registrar(
        tipo: s.esGasto ? TipoMovimiento.gasto : TipoMovimiento.ingreso,
        monto: s.monto,
        categoriaId: categoria.id!,
        fecha: hoy,
        descripcion: s.descripcion,
        origen: OrigenMovimiento.ia,
      );
      if (categoria.nombre == categoriaHorasExtras) {
        await AvisosRepositorio(txn).marcar(AvisosRepositorio.horasExtras, Periodo.de(hoy));
      }
      final fijo = p.fijo;
      if (fijo != null && conciliarConFijo) {
        await ServicioPlanes(txn).enlazar(fijo.id!, Periodo.de(hoy), movimientoId);
        if (actualizarMontoFijo) await ServicioPlanes(txn).actualizar(fijo.copiaCon(monto: s.monto));
      }
    });
    _quitar(p);
  }

  void descartar(PropuestaOtto p) => _quitar(p);

  void _quitar(PropuestaOtto p) {
    final restantes = state.propuestas.where((x) => x.id != p.id).toList();
    state = EstadoChatOtto(
      estado: restantes.isEmpty ? EstadoOtto.inactivo : EstadoOtto.sugerencia,
      propuestas: restantes,
    );
  }

  Categoria? _categoria(List<Categoria> categorias, int? id, String tipo) {
    final elegida = categorias.where((c) => c.id == id && c.tipo == tipo).firstOrNull;
    if (elegida != null) return elegida;
    final porDefecto = tipo == 'gasto' ? 'otros' : 'sueldo';
    final delTipo = categorias.where((c) => c.tipo == tipo);
    return delTipo.where((c) => normalizar(c.nombre).contains(porDefecto)).firstOrNull ?? delTipo.firstOrNull;
  }
}
