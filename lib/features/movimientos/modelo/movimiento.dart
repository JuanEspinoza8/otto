class Movimiento {
  final int? id;
  final double monto;
  final DateTime fecha;
  final String? descripcion;
  final String tipo; // 'ingreso', 'gasto' o 'ahorro'
  final int? categoriaId; // null en movimientos de tipo 'ahorro'
  final int? metaId; // meta destino (sólo en 'ahorro')
  final double? montoMeta; // monto en la moneda de la meta (sólo en 'ahorro')

  Movimiento({
    this.id,
    required this.monto,
    required this.fecha,
    this.descripcion,
    required this.tipo,
    this.categoriaId,
    this.metaId,
    this.montoMeta,
  });

  /// Un aporte a una meta de ahorro (plata que salió del bolsillo libre).
  bool get esAhorro => tipo == 'ahorro';

  /// Convierte el objeto a un mapa para SQLite.
  /// Se multiplica monto por 100 para almacenar precisión entera.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monto': (monto * 100).round(),
      'fecha': fecha.millisecondsSinceEpoch,
      'descripcion': descripcion,
      'tipo': tipo,
      'categoria_id': categoriaId,
      'meta_id': metaId,
      'monto_meta': montoMeta == null ? null : (montoMeta! * 100).round(),
    };
  }

  /// Crea un objeto a partir del mapa devuelto por SQLite.
  /// Se divide monto por 100 para restaurar el valor real.
  factory Movimiento.fromMap(Map<String, dynamic> mapa) {
    return Movimiento(
      id: mapa['id'] as int?,
      monto: (mapa['monto'] as num).toDouble() / 100,
      fecha: DateTime.fromMillisecondsSinceEpoch(mapa['fecha'] as int),
      descripcion: mapa['descripcion'] as String?,
      tipo: mapa['tipo'] as String,
      categoriaId: mapa['categoria_id'] as int?,
      metaId: mapa['meta_id'] as int?,
      montoMeta: mapa['monto_meta'] == null ? null : (mapa['monto_meta'] as num).toDouble() / 100,
    );
  }
}
