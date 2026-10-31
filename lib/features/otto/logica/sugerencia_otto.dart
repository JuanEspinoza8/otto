import '../../../core/dinero/dinero.dart';

/// Un movimiento que Otto entendió de un mensaje.
class SugerenciaOtto {
  const SugerenciaOtto({
    required this.tipo,
    required this.monto,
    required this.descripcion,
    this.categoriaId,
    this.horas,
  });

  /// 'ingreso' o 'gasto'.
  final String tipo;
  final Dinero monto;
  final String descripcion;
  final int? categoriaId;

  /// Si el mensaje habla de horas ("hice 3 horas extra"): con la categoría
  /// de horas extra se cargan horas × valor de la hora, como en el formulario.
  final double? horas;

  bool get esGasto => tipo == 'gasto';
}
