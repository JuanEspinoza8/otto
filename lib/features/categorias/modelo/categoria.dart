class Categoria {
  final int? id;
  final String nombre;
  final String tipo; // 'ingreso' o 'gasto'
  final String colorHex;
  final String icono;
  final double presupuestoLimite;
  final bool esSistema;

  Categoria({
    this.id,
    required this.nombre,
    required this.tipo,
    required this.colorHex,
    required this.icono,
    this.presupuestoLimite = 0.0,
    this.esSistema = false,
  });

  /// Convierte el objeto a un mapa para SQLite.
  /// Se multiplica presupuestoLimite por 100 para almacenar precisión entera.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'color_hex': colorHex,
      'icono': icono,
      'presupuesto_limite': (presupuestoLimite * 100).round(),
      'es_sistema': esSistema ? 1 : 0,
    };
  }

  /// Crea un objeto a partir del mapa devuelto por SQLite.
  /// Se divide presupuesto_limite por 100 para restaurar el valor real.
  factory Categoria.fromMap(Map<String, dynamic> mapa) {
    return Categoria(
      id: mapa['id'] as int?,
      nombre: mapa['nombre'] as String,
      tipo: mapa['tipo'] as String,
      colorHex: mapa['color_hex'] as String,
      icono: mapa['icono'] as String,
      presupuestoLimite: (mapa['presupuesto_limite'] as num).toDouble() / 100,
      esSistema: (mapa['es_sistema'] as int) == 1,
    );
  }
}
