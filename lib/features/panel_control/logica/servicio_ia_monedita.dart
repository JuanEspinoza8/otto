import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/utilidades/configuracion_ia.dart';
import '../../categorias/modelo/categoria.dart';
import 'servicio_monedita.dart';

/// Servicio de IA de Otto usando Pollinations (endpoint compatible con OpenAI).
///
/// Interpreta un mensaje que puede contener VARIOS movimientos en una sola
/// frase (ej. "pagué 50mil de luz y el disney me salió 4mil") y devuelve una
/// lista de [SugerenciaMonedita]. Si falla (sin red, error, JSON inválido)
/// devuelve lista vacía para que el llamador use el parser local.
class ServicioIaMonedita {
  static Future<List<SugerenciaMonedita>> interpretar(
    String mensaje,
    List<Categoria> categorias,
  ) async {
    if (!ConfiguracionIA.estaConfigurada || mensaje.trim().isEmpty) return [];

    try {
      final listaCategorias =
          categorias.map((c) => '${c.id}: ${c.nombre} (${c.tipo})').join(', ');

      const system =
          'Sos "Otto", un asistente argentino que interpreta mensajes coloquiales sobre gastos e ingresos y los convierte en JSON estructurado. Respondés ÚNICAMENTE con JSON válido, sin texto adicional.';

      final user = '''
Categorías disponibles (formato "id: nombre (tipo)"): $listaCategorias

Mensaje del usuario: "$mensaje"

Puede haber VARIOS movimientos en la frase. Devolvé un JSON con esta forma exacta:
{"movimientos":[{"tipo":"gasto" o "ingreso","monto":<número en pesos sin separadores>,"categoriaId":<id entero de la lista que mejor aplique y del tipo correcto, o null>,"descripcion":"<texto corto>"}]}

Reglas:
- "luca"/"lucas"/"k" = miles; "palo" = millón. Ej: "50 lucas" = 50000.
- Elegí categoriaId SOLO entre los ids de la lista y del mismo tipo.
- Si no identificás un monto para un ítem, no lo incluyas.
- No agregues texto fuera del JSON.''';

      final cuerpo = jsonEncode({
        'model': ConfiguracionIA.modelo,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
        'temperature': 0.2,
        // Pedimos salida JSON con el estándar OpenAI (el prompt ya la exige y
        // _extraerJson tolera texto de más). No usamos flags propietarios.
        'response_format': {'type': 'json_object'},
      });

      final respuesta = await http
          .post(
            Uri.parse(ConfiguracionIA.endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${ConfiguracionIA.apiKey}',
            },
            body: cuerpo,
          )
          .timeout(const Duration(seconds: 25));

      if (respuesta.statusCode != 200) {
        debugPrint('Pollinations error ${respuesta.statusCode}: ${respuesta.body}');
        return [];
      }

      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
      final contenido = datos['choices']?[0]?['message']?['content'];

      final obj = _extraerJson(contenido);
      if (obj == null) return [];

      final movs = obj['movimientos'];
      if (movs is! List) return [];

      return movs
          .map((m) => _parsear(m, categorias))
          .whereType<SugerenciaMonedita>()
          .toList();
    } catch (error) {
      debugPrint('Fallo IA Otto: $error');
      return [];
    }
  }

  /// El contenido puede venir como objeto, como string JSON, o con fences ```.
  static Map<String, dynamic>? _extraerJson(dynamic contenido) {
    try {
      if (contenido is Map) return contenido.cast<String, dynamic>();
      if (contenido is String) {
        var s = contenido.trim();
        // Quitar fences de markdown si los hubiera.
        s = s.replaceAll(RegExp(r'^```(json)?'), '').replaceAll(RegExp(r'```$'), '').trim();
        // Tomar desde la primera llave por las dudas.
        final inicio = s.indexOf('{');
        final fin = s.lastIndexOf('}');
        if (inicio >= 0 && fin > inicio) s = s.substring(inicio, fin + 1);
        return jsonDecode(s) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('JSON IA inválido: $e');
    }
    return null;
  }

  static SugerenciaMonedita? _parsear(dynamic m, List<Categoria> categorias) {
    if (m is! Map) return null;
    try {
      final tipo = (m['tipo'] as String?)?.toLowerCase() == 'ingreso' ? 'ingreso' : 'gasto';

      final montoRaw = m['monto'];
      final monto = montoRaw is num ? montoRaw.toDouble() : double.tryParse('${montoRaw ?? ''}') ?? 0;
      if (monto <= 0) return null;

      int? categoriaId;
      final idRaw = m['categoriaId'];
      if (idRaw is num) {
        categoriaId = idRaw.toInt();
      } else if (idRaw is String) {
        categoriaId = int.tryParse(idRaw);
      }

      String? nombreCategoria;
      if (categoriaId != null) {
        final match = categorias.where((c) => c.id == categoriaId);
        if (match.isEmpty || match.first.tipo != tipo) {
          categoriaId = null;
        } else {
          nombreCategoria = match.first.nombre;
        }
      }

      final descripcion = (m['descripcion'] as String?)?.trim();

      return SugerenciaMonedita(
        tipo: tipo,
        monto: monto,
        categoriaId: categoriaId,
        nombreCategoria: nombreCategoria,
        descripcion: descripcion?.isNotEmpty == true ? descripcion! : 'Movimiento',
        confianza: categoriaId != null ? NivelConfianza.alta : NivelConfianza.media,
      );
    } catch (e) {
      return null;
    }
  }
}
