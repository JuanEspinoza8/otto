/// Entidad que representa una submeta dentro de una meta de ahorro.
class Submeta {
  final int? id;
  final String nombre;
  final String icono;
  final double montoObjetivo;
  final double montoActual;
  final int metaId;

  Submeta({
    this.id,
    required this.nombre,
    this.icono = 'flag',
    required this.montoObjetivo,
    this.montoActual = 0.0,
    required this.metaId,
  });

  /// Convierte el objeto a un mapa para SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'icono': icono,
      'monto_objetivo': (montoObjetivo * 100).round(),
      'monto_actual': (montoActual * 100).round(),
      'meta_id': metaId,
    };
  }

  /// Crea un objeto a partir del mapa devuelto por SQLite.
  factory Submeta.fromMap(Map<String, dynamic> mapa) {
    return Submeta(
      id: mapa['id'] as int?,
      nombre: mapa['nombre'] as String,
      icono: mapa['icono'] as String,
      montoObjetivo: (mapa['monto_objetivo'] as num).toDouble() / 100,
      montoActual: (mapa['monto_actual'] as num).toDouble() / 100,
      metaId: mapa['meta_id'] as int,
    );
  }

  /// Calcula el porcentaje de progreso de la submeta.
  double get porcentajeProgreso {
    if (montoObjetivo <= 0) return 0;
    return (montoActual / montoObjetivo * 100).clamp(0, 100);
  }
}
