import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'ahorros_provider.dart';
import 'dashboard_provider.dart';
import 'dolar_blue_provider.dart';
import 'metas_provider.dart';

part 'ahorro_disponible_provider.g.dart';

/// Plata realmente libre para gastar o asignar a metas: un único número,
/// consistente en todo lado (dashboard, formulario y diálogos).
///
/// disponible = ahorro previo (ARS + USD→ARS)
///            + (todos los ingresos históricos − todos los gastos históricos)
///            − lo que hoy está guardado en metas
///
/// Es un **saldo corrido** (histórico), no del mes: así no se rompe al cambiar
/// de mes ni deja "plata fantasma" cuando se asigna a una meta. Cuando aportás
/// a una meta sube "lo guardado en metas" y este número baja en el acto.
@riverpod
double ahorroDisponible(AhorroDisponibleRef ref) {
  final ahorros = ref.watch(ahorrosControladorProvider).valueOrNull;
  final blue = ref.watch(dolarBlueProvider).valueOrNull?['venta'] ?? 0.0;
  final tot = ref.watch(totalesGlobalesProvider).valueOrNull ?? const {};
  final asignado = ref.watch(progresoMetaTotalProvider)['montoActual'] ?? 0.0;

  final previoArs = ahorros?.ahorroPrevioArs ?? 0.0;
  final previoUsdEnArs = (ahorros?.ahorroPrevioUsd ?? 0.0) * blue;

  final ingresos = tot['ingresos'] ?? 0.0;
  final gastos = tot['gastos'] ?? 0.0;

  // Puede quedar negativo (sobregiro): se devuelve tal cual para no ocultar
  // que se gastó más de lo que había. La tarjeta lo muestra en rojo.
  return previoArs + previoUsdEnArs + ingresos - gastos - asignado;
}
