import '../../../core/dinero/dinero.dart';

/// Estado del gasto de una categoría contra su presupuesto mensual.
enum NivelPresupuesto {
  /// Menos del 80%.
  normal,

  /// Del 80% al 100%: alerta amarilla.
  alerta,

  /// Más del 100%: alerta roja.
  excedido,
}

const double umbralAlerta = 0.8;

NivelPresupuesto nivelPresupuesto(Dinero gastado, Dinero limite) {
  if (!limite.esPositivo) return NivelPresupuesto.normal;
  final ratio = gastado.centavos / limite.centavos;
  if (ratio > 1) return NivelPresupuesto.excedido;
  if (ratio >= umbralAlerta) return NivelPresupuesto.alerta;
  return NivelPresupuesto.normal;
}

/// Mensaje para avisar al registrar un gasto, si el gasto hizo cruzar un
/// umbral (de normal a alerta, o a excedido). Null si no cambió nada.
String? avisoPresupuesto(String categoria, Dinero antes, Dinero despues, Dinero limite) {
  final previo = nivelPresupuesto(antes, limite);
  final actual = nivelPresupuesto(despues, limite);
  if (actual == previo || actual == NivelPresupuesto.normal) return null;
  return actual == NivelPresupuesto.excedido
      ? 'Te pasaste del presupuesto de $categoria por ${(despues - limite).formatear()}'
      : 'Llegaste al ${(despues.centavos / limite.centavos * 100).floor()}% del presupuesto de $categoria';
}
