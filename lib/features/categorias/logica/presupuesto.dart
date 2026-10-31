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

/// Porcentaje del presupuesto desde el que se avisa.
const int umbralAlerta = 80;

NivelPresupuesto nivelPresupuesto(Dinero gastado, Dinero limite) {
  if (!limite.esPositivo) return NivelPresupuesto.normal;
  if (gastado > limite) return NivelPresupuesto.excedido;
  if (gastado.porcentajeDe(limite) >= umbralAlerta) return NivelPresupuesto.alerta;
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
      : 'Llegaste al ${despues.porcentajeDe(limite)}% del presupuesto de $categoria';
}
