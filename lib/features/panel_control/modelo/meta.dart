/// Entidad que representa una meta de ahorro del usuario.
class Meta {
  final int? id;
  final String nombre;
  final String icono;
  final double montoObjetivo;
  final double montoActual;
  final String moneda; // 'ARS' o 'USD'
  final DateTime fechaCreacion;

  Meta({
    this.id,
    required this.nombre,
    this.icono = 'flag',
    required this.montoObjetivo,
    this.montoActual = 0.0,
    this.moneda = 'ARS',
    required this.fechaCreacion,
  });

  bool get esUsd => moneda == 'USD';

  /// Convierte el objeto a un mapa para SQLite.
  /// Se multiplica por 100 para almacenar precisión entera.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'icono': icono,
      'monto_objetivo': (montoObjetivo * 100).round(),
      'monto_actual': (montoActual * 100).round(),
      'moneda': moneda,
      'fecha_creacion': fechaCreacion.millisecondsSinceEpoch,
    };
  }

  /// Crea un objeto a partir del mapa devuelto por SQLite.
  /// Se divide por 100 para restaurar el valor real.
  factory Meta.fromMap(Map<String, dynamic> mapa) {
    return Meta(
      id: mapa['id'] as int?,
      nombre: mapa['nombre'] as String,
      icono: mapa['icono'] as String,
      montoObjetivo: (mapa['monto_objetivo'] as num).toDouble() / 100,
      montoActual: (mapa['monto_actual'] as num).toDouble() / 100,
      moneda: (mapa['moneda'] as String?) ?? 'ARS',
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(mapa['fecha_creacion'] as int),
    );
  }

  /// Calcula el porcentaje de progreso de la meta.
  double get porcentajeProgreso {
    if (montoObjetivo <= 0) return 0;
    return (montoActual / montoObjetivo * 100).clamp(0, 100);
  }

  /// Indica si ya se alcanzó (o superó) el objetivo.
  bool get cumplida => montoActual >= montoObjetivo && montoObjetivo > 0;

  Meta copiaCon({
    int? id,
    String? nombre,
    String? icono,
    double? montoObjetivo,
    double? montoActual,
    String? moneda,
    DateTime? fechaCreacion,
  }) {
    return Meta(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      icono: icono ?? this.icono,
      montoObjetivo: montoObjetivo ?? this.montoObjetivo,
      montoActual: montoActual ?? this.montoActual,
      moneda: moneda ?? this.moneda,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
