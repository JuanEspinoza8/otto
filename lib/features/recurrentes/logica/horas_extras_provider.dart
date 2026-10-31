import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/libro/libro_providers.dart';
import '../../../core/libro/modelo/movimiento.dart';
import '../../../core/libro/servicio_libro.dart';
import '../../../core/utilidades/fechas.dart';
import '../../configuracion/repositorio/ajustes_repositorio.dart';
import '../repositorio/avisos_repositorio.dart';

part 'horas_extras_provider.g.dart';

/// Nombre de la categoría de ingresos en la que el monto se carga en horas.
const String categoriaHorasExtras = 'Horas extras';

/// Regla única de horas extra (formulario, pregunta mensual y Otto): el
/// ingreso es horas × valor de la hora, y si es del mes actual la pregunta
/// mensual queda respondida para no contarlas dos veces.
Future<int> registrarHorasExtras(
  DatabaseExecutor txn, {
  required double horas,
  required DateTime fecha,
  String? descripcion,
  OrigenMovimiento origen = OrigenMovimiento.manual,
}) async {
  if (horas <= 0) throw const ErrorLibro('Ingresá la cantidad de horas');
  final valor = await AjustesRepositorio(txn).valorHoraExtra();
  if (!valor.esPositivo) throw const ErrorLibro('Configurá el valor de la hora extra en Menú');
  final categoria = await txn.query('categorias',
      where: "tipo = 'ingreso' AND nombre = ?", whereArgs: [categoriaHorasExtras], limit: 1);
  if (categoria.isEmpty) throw const ErrorLibro('Falta la categoría "$categoriaHorasExtras"');

  final horasTexto = horas % 1 == 0 ? horas.toStringAsFixed(0) : horas.toString().replaceAll('.', ',');
  final id = await ServicioLibro(txn).registrar(
    tipo: TipoMovimiento.ingreso,
    monto: valor.por(horas),
    categoriaId: categoria.first['id'] as int,
    fecha: fecha,
    descripcion: (descripcion == null || descripcion.trim().isEmpty) ? '$horasTexto horas extra' : descripcion,
    origen: origen,
  );
  final periodo = Periodo.de(fecha);
  if (periodo == Periodo.de(DateTime.now())) {
    await AvisosRepositorio(txn).marcar(AvisosRepositorio.horasExtras, periodo);
  }
  return id;
}

/// Pregunta mensual "¿hiciste horas extras?".
class EstadoHorasExtras {
  const EstadoHorasExtras({required this.preguntar, required this.valorHora});
  final bool preguntar;
  final Dinero valorHora;
}

@riverpod
class HorasExtrasMes extends _$HorasExtrasMes {
  @override
  Future<EstadoHorasExtras> build() async {
    ref.watch(versionDatosProvider);
    final db = await ref.watch(baseDatosProvider.future);
    final valor = await AjustesRepositorio(db).valorHoraExtra();
    final respondida = await AvisosRepositorio(db).resuelto(AvisosRepositorio.horasExtras, Periodo.de(DateTime.now()));
    return EstadoHorasExtras(preguntar: valor.esPositivo && !respondida, valorHora: valor);
  }

  Future<void> registrarHoras(double horas, {DateTime? fecha, String? descripcion}) => escribirEnTransaccion(
      ref, (txn) => registrarHorasExtras(txn, horas: horas, fecha: fecha ?? DateTime.now(), descripcion: descripcion));

  /// El usuario respondió "no" este mes: no se vuelve a preguntar.
  Future<void> descartar() => escribirEnTransaccion(
      ref, (txn) => AvisosRepositorio(txn).marcar(AvisosRepositorio.horasExtras, Periodo.de(DateTime.now())));
}
