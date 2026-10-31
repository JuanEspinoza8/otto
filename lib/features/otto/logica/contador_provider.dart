import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utilidades/fechas.dart';
import '../../configuracion/logica/ajustes_provider.dart';
import '../../panel_control/logica/dashboard_provider.dart';
import '../../panel_control/logica/metas_provider.dart';
import 'servicio_ia_contador.dart';

part 'contador_provider.g.dart';

/// Devolución de Otto contador para un mes, o null si la IA está apagada o
/// no respondió. La respuesta queda guardada por mes (ver ServicioIaContador).
@riverpod
Future<String?> devolucionContador(Ref ref, Periodo mes) async {
  if (!(await ref.watch(ajustesControladorProvider.future)).iaActiva) return null;
  final resumen = await ref.watch(resumenDeMesProvider(mes).future);
  if (resumen.vacio) return null;
  final metas = await ref.watch(metasControladorProvider.future);
  final metasResumen = metas.map((m) => '${m.nombre} ${m.porcentajeProgreso}%').join(', ');
  return ServicioIaContador.evaluar(resumen, metasResumen: metasResumen);
}
