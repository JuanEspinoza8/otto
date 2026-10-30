import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../core/utilidades/configuracion_ia.dart';
import 'servicio_resumen_mes.dart';

/// Pide a la IA (Pollinations) una devolución del mes en rol de contador.
class ServicioIaContador {
  static Future<String?> evaluar(ResumenMesData resumen, {String? metasResumen}) async {
    if (!ConfiguracionIA.estaConfigurada) return null;
    try {
      final f = NumberFormat('#,##0.##', 'es_AR');
      final egresosTxt = resumen.egresos.map((e) => '${e.nombre}: \$${f.format(e.monto)}').join(', ');
      final ingresosTxt = resumen.ingresos.map((e) => '${e.nombre}: \$${f.format(e.monto)}').join(', ');

      final user = '''
Sos un contador amable y claro. Analizá este mes y dame una devolución BREVE (3 a 5 frases), en español rioplatense, sin markdown ni listas, con un consejo práctico.

Ingresos totales: \$${f.format(resumen.totalIngresos)} ($ingresosTxt).
Egresos totales: \$${f.format(resumen.totalEgresos)} ($egresosTxt).
Sobrante del mes: \$${f.format(resumen.sobrante)}.
${metasResumen != null && metasResumen.isNotEmpty ? 'Metas de ahorro: $metasResumen.' : ''}

Evaluá qué tan bien administró el mes, resaltá el gasto más pesado y si el ahorro es sano.''';

      final cuerpo = jsonEncode({
        'model': ConfiguracionIA.modelo,
        'messages': [
          {'role': 'system', 'content': 'Sos "Otto", un contador simpático que da devoluciones cortas y útiles.'},
          {'role': 'user', 'content': user},
        ],
        'temperature': 0.6,
      });

      final respuesta = await http
          .post(
            Uri.parse(ConfiguracionIA.endpoint),
            headers: ConfiguracionIA.encabezados,
            body: cuerpo,
          )
          .timeout(const Duration(seconds: 25));

      if (respuesta.statusCode != 200) {
        debugPrint('IA contador error ${respuesta.statusCode}');
        return null;
      }
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
      final contenido = datos['choices']?[0]?['message']?['content'];
      if (contenido is String && contenido.trim().isNotEmpty) return contenido.trim();
      return null;
    } catch (e) {
      debugPrint('Fallo IA contador: $e');
      return null;
    }
  }
}
