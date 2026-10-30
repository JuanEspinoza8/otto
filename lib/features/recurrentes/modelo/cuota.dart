/// Entidad de una cuota en pago (ej. una compra en N cuotas).
///
/// Deja de descontarse automáticamente cuando [cuotasPagadas] alcanza
/// [totalCuotas] (la marca [finalizada] pasa a `true`).
class Cuota {
  final int? id;
  final String nombre;
  final double montoCuota;
  final int? categoriaId;
  final int totalCuotas;
  final int cuotasPagadas;
  final int diaDebito;
  final bool activo;

  Cuota({
    this.id,
    required this.nombre,
    required this.montoCuota,
    this.categoriaId,
    required this.totalCuotas,
    this.cuotasPagadas = 0,
    this.diaDebito = 1,
    this.activo = true,
  });

  /// Cuotas que faltan pagar.
  int get cuotasRestantes => (totalCuotas - cuotasPagadas).clamp(0, totalCuotas);

  /// Indica si ya se terminaron de pagar todas las cuotas.
  bool get finalizada => cuotasPagadas >= totalCuotas;

  /// Porcentaje pagado (0–100).
  double get porcentaje =>
      totalCuotas <= 0 ? 0 : (cuotasPagadas / totalCuotas * 100).clamp(0, 100);

  /// Total restante a pagar.
  double get montoRestante => montoCuota * cuotasRestantes;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'monto_cuota': (montoCuota * 100).round(),
      'categoria_id': categoriaId,
      'total_cuotas': totalCuotas,
      'cuotas_pagadas': cuotasPagadas,
      'dia_debito': diaDebito,
      'activo': activo ? 1 : 0,
    };
  }

  factory Cuota.fromMap(Map<String, dynamic> mapa) {
    return Cuota(
      id: mapa['id'] as int?,
      nombre: mapa['nombre'] as String,
      montoCuota: (mapa['monto_cuota'] as num).toDouble() / 100,
      categoriaId: mapa['categoria_id'] as int?,
      totalCuotas: mapa['total_cuotas'] as int,
      cuotasPagadas: mapa['cuotas_pagadas'] as int? ?? 0,
      diaDebito: mapa['dia_debito'] as int? ?? 1,
      activo: (mapa['activo'] as int? ?? 1) == 1,
    );
  }

  Cuota copiaCon({
    int? id,
    String? nombre,
    double? montoCuota,
    int? categoriaId,
    int? totalCuotas,
    int? cuotasPagadas,
    int? diaDebito,
    bool? activo,
  }) {
    return Cuota(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      montoCuota: montoCuota ?? this.montoCuota,
      categoriaId: categoriaId ?? this.categoriaId,
      totalCuotas: totalCuotas ?? this.totalCuotas,
      cuotasPagadas: cuotasPagadas ?? this.cuotasPagadas,
      diaDebito: diaDebito ?? this.diaDebito,
      activo: activo ?? this.activo,
    );
  }
}
