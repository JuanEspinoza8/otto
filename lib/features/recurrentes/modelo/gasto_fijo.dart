/// Entidad de un gasto fijo mensual (servicios, alquiler, impuestos, etc.).
class GastoFijo {
  final int? id;
  final String nombre;
  final double monto;
  final int? categoriaId;
  final int diaDebito; // día del mes en que se debita (1..28)
  final bool activo;

  GastoFijo({
    this.id,
    required this.nombre,
    required this.monto,
    this.categoriaId,
    this.diaDebito = 1,
    this.activo = true,
  });

  /// Se multiplica por 100 para almacenar precisión entera en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'monto': (monto * 100).round(),
      'categoria_id': categoriaId,
      'dia_debito': diaDebito,
      'activo': activo ? 1 : 0,
    };
  }

  factory GastoFijo.fromMap(Map<String, dynamic> mapa) {
    return GastoFijo(
      id: mapa['id'] as int?,
      nombre: mapa['nombre'] as String,
      monto: (mapa['monto'] as num).toDouble() / 100,
      categoriaId: mapa['categoria_id'] as int?,
      diaDebito: mapa['dia_debito'] as int? ?? 1,
      activo: (mapa['activo'] as int? ?? 1) == 1,
    );
  }

  GastoFijo copiaCon({
    int? id,
    String? nombre,
    double? monto,
    int? categoriaId,
    int? diaDebito,
    bool? activo,
  }) {
    return GastoFijo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      monto: monto ?? this.monto,
      categoriaId: categoriaId ?? this.categoriaId,
      diaDebito: diaDebito ?? this.diaDebito,
      activo: activo ?? this.activo,
    );
  }
}
