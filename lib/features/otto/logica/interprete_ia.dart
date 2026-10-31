import 'dart:convert';

import '../../../core/dinero/dinero.dart';
import '../../categorias/modelo/categoria.dart';
import 'cliente_ia.dart';
import 'sugerencia_otto.dart';

/// Interpreta con IA un mensaje que puede tener varios movimientos ("pagué
/// 50mil de luz y el disney me salió 4mil"). Envía el texto y la lista de
/// categorías. Si algo falla devuelve una lista vacía y el chat usa el
/// parser local.
class InterpreteIa {
  static const _sistema =
      'Sos "Otto", un asistente argentino que convierte mensajes coloquiales sobre gastos e '
      'ingresos en JSON. Respondés ÚNICAMENTE con JSON válido, sin texto adicional.';

  static Future<List<SugerenciaOtto>> interpretar(String mensaje, List<Categoria> categorias) async {
    if (mensaje.trim().isEmpty) return const [];
    final lista = categorias.map((c) => '${c.id}: ${c.nombre} (${c.tipo})').join(', ');
    final usuario = '''
Categorías disponibles (formato "id: nombre (tipo)"): $lista

Mensaje del usuario: "$mensaje"

Puede haber VARIOS movimientos en la frase. Devolvé un JSON con esta forma exacta:
{"movimientos":[{"tipo":"gasto" o "ingreso","monto":<número en pesos, sin separadores de miles>,"categoriaId":<id de la lista del mismo tipo, o null>,"descripcion":"<texto corto>","horas":<cantidad si el mensaje habla de horas, si no null>}]}

Reglas:
- "luca"/"lucas"/"k" = miles; "palo" = millón. Ej: "50 lucas" = 50000.
- Elegí categoriaId SOLO entre los ids de la lista y del mismo tipo.
- Si no identificás un monto para un ítem, no lo incluyas.''';

    final contenido = await ClienteIa.completar(sistema: _sistema, usuario: usuario, temperatura: 0.2, json: true);
    final objeto = _extraerJson(contenido);
    final movimientos = objeto?['movimientos'];
    if (movimientos is! List) return const [];
    return movimientos.map((m) => _parsear(m, categorias)).whereType<SugerenciaOtto>().toList();
  }

  /// El contenido puede venir con texto o fences de markdown alrededor.
  static Map<String, dynamic>? _extraerJson(String? contenido) {
    if (contenido == null) return null;
    final inicio = contenido.indexOf('{');
    final fin = contenido.lastIndexOf('}');
    if (inicio < 0 || fin <= inicio) return null;
    try {
      final valor = jsonDecode(contenido.substring(inicio, fin + 1));
      return valor is Map<String, dynamic> ? valor : null;
    } catch (_) {
      return null;
    }
  }

  static SugerenciaOtto? _parsear(Object? m, List<Categoria> categorias) {
    if (m is! Map) return null;
    final tipo = '${m['tipo']}'.toLowerCase() == 'ingreso' ? 'ingreso' : 'gasto';

    // El monto puede llegar como número o como texto ("50.000"): el texto
    // pasa por el mismo parser que el resto de la app.
    final crudo = m['monto'];
    final monto = crudo is num ? Dinero.desdeUnidades(crudo) : Dinero.parsear('${crudo ?? ''}');
    if (monto == null || !monto.esPositivo) return null;

    final idCrudo = m['categoriaId'];
    var categoriaId = idCrudo is num ? idCrudo.toInt() : int.tryParse('${idCrudo ?? ''}');
    final categoria = categorias.where((c) => c.id == categoriaId).firstOrNull;
    if (categoria == null || categoria.tipo != tipo) categoriaId = null;

    final horasCrudo = m['horas'];
    final horas = horasCrudo is num && horasCrudo > 0 ? horasCrudo.toDouble() : null;
    final descripcion = '${m['descripcion'] ?? ''}'.trim();

    return SugerenciaOtto(
      tipo: tipo,
      monto: monto,
      categoriaId: categoriaId,
      descripcion: descripcion.isEmpty ? 'Movimiento' : descripcion,
      horas: horas,
    );
  }
}
