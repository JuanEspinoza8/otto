import '../../../core/dinero/dinero.dart';

class Categoria {
  const Categoria({
    this.id,
    required this.nombre,
    required this.tipo,
    required this.colorHex,
    required this.icono,
    this.presupuestoLimite = const Dinero.cero(),
    this.esSistema = false,
  });

  final int? id;
  final String nombre;
  final String tipo; // 'ingreso' o 'gasto'
  final String colorHex;
  final String icono;

  /// Límite mensual de gasto (cero = sin presupuesto).
  final Dinero presupuestoLimite;
  final bool esSistema;

  bool get esGasto => tipo == 'gasto';

  Map<String, Object?> aFila() => {
        if (id != null) 'id': id,
        'nombre': nombre.trim(),
        'tipo': tipo,
        'color_hex': colorHex,
        'icono': icono,
        'presupuesto_limite': presupuestoLimite.centavos,
        'es_sistema': esSistema ? 1 : 0,
      };

  factory Categoria.desdeFila(Map<String, Object?> fila) => Categoria(
        id: fila['id'] as int?,
        nombre: fila['nombre'] as String,
        tipo: fila['tipo'] as String,
        colorHex: fila['color_hex'] as String,
        icono: fila['icono'] as String,
        presupuestoLimite: Dinero((fila['presupuesto_limite'] as int?) ?? 0),
        esSistema: fila['es_sistema'] == 1,
      );

  Categoria copiaCon({String? nombre, String? tipo, String? colorHex, String? icono, Dinero? presupuestoLimite}) =>
      Categoria(
        id: id,
        nombre: nombre ?? this.nombre,
        tipo: tipo ?? this.tipo,
        colorHex: colorHex ?? this.colorHex,
        icono: icono ?? this.icono,
        presupuestoLimite: presupuestoLimite ?? this.presupuestoLimite,
        esSistema: esSistema,
      );
}
