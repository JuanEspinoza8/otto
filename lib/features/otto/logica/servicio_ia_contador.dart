import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../panel_control/logica/servicio_resumen_mes.dart';
import 'cliente_ia.dart';

/// Devolución del mes de Otto en rol de contador.
///
/// Envía a la IA los totales por categoría, el sobrante y el avance de las
/// metas. La respuesta se guarda por mes: mientras los totales no cambien,
/// abrir el resumen no vuelve a llamar (cada llamada se paga).
class ServicioIaContador {
  static const _sistema = 'Sos "Otto", un contador simpático que da devoluciones cortas y útiles.';

  static Future<String?> evaluar(ResumenMesData resumen, {String? metasResumen}) async {
    final prefs = await SharedPreferences.getInstance();
    final clave = 'contador_${resumen.mes}';
    final huella = '${resumen.totalIngresos.centavos}:${resumen.totalEgresos.centavos}:'
        '${resumen.ingresos.length}:${resumen.egresos.length}:${metasResumen ?? ''}';

    final guardado = _leer(prefs.getString(clave));
    if (guardado != null && guardado['huella'] == huella) return guardado['texto'] as String?;

    final egresos = resumen.egresos.map((e) => '${e.nombre}: ${e.monto.formatear()}').join(', ');
    final ingresos = resumen.ingresos.map((e) => '${e.nombre}: ${e.monto.formatear()}').join(', ');
    final usuario = '''
Sos un contador amable y claro. Analizá este mes y dame una devolución BREVE (3 a 5 frases), en español rioplatense, sin markdown ni listas, con un consejo práctico.

Ingresos totales: ${resumen.totalIngresos.formatear()} ($ingresos).
Egresos totales: ${resumen.totalEgresos.formatear()} ($egresos).
Sobrante del mes: ${resumen.sobrante.formatear()}.
${metasResumen != null && metasResumen.isNotEmpty ? 'Metas de ahorro: $metasResumen.' : ''}

Evaluá qué tan bien administró el mes, resaltá el gasto más pesado y si el ahorro es sano.''';

    final texto = await ClienteIa.completar(sistema: _sistema, usuario: usuario, temperatura: 0.6);
    if (texto != null) {
      await prefs.setString(clave, jsonEncode({'huella': huella, 'texto': texto}));
    }
    return texto;
  }

  static Map<String, dynamic>? _leer(String? json) {
    if (json == null) return null;
    try {
      final valor = jsonDecode(json);
      return valor is Map<String, dynamic> ? valor : null;
    } catch (_) {
      return null;
    }
  }
}
