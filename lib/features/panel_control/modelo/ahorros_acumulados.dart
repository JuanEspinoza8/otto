/// Entidad que almacena los ahorros previos del usuario (fila única en la BD).
class AhorrosAcumulados {
  final int id; // Siempre 1
  final double ahorroPrevioArs;
  final double ahorroPrevioUsd;

  AhorrosAcumulados({
    this.id = 1,
    this.ahorroPrevioArs = 0.0,
    this.ahorroPrevioUsd = 0.0,
  });

  /// Convierte el objeto a un mapa para SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ahorro_previo_ars': (ahorroPrevioArs * 100).round(),
      'ahorro_previo_usd': (ahorroPrevioUsd * 100).round(),
    };
  }

  /// Crea un objeto a partir del mapa devuelto por SQLite.
  factory AhorrosAcumulados.fromMap(Map<String, dynamic> mapa) {
    return AhorrosAcumulados(
      id: mapa['id'] as int,
      ahorroPrevioArs: (mapa['ahorro_previo_ars'] as num).toDouble() / 100,
      ahorroPrevioUsd: (mapa['ahorro_previo_usd'] as num).toDouble() / 100,
    );
  }
}
