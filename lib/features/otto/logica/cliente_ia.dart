import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/utilidades/configuracion_ia.dart';

/// Llamada al proxy de IA (API de chat compatible con OpenAI).
///
/// Devuelve el texto de la respuesta o null si la IA no está configurada,
/// no hay red o la respuesta no sirve. Nunca registra el contenido de los
/// mensajes ni de las respuestas.
class ClienteIa {
  static Future<String?> completar({
    required String sistema,
    required String usuario,
    double temperatura = 0.3,
    bool json = false,
  }) async {
    if (!ConfiguracionIA.estaConfigurada) return null;
    try {
      final respuesta = await http
          .post(
            Uri.parse(ConfiguracionIA.endpoint),
            headers: ConfiguracionIA.encabezados,
            body: jsonEncode({
              'model': ConfiguracionIA.modelo,
              'messages': [
                {'role': 'system', 'content': sistema},
                {'role': 'user', 'content': usuario},
              ],
              'temperature': temperatura,
              if (json) 'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(const Duration(seconds: 25));
      if (respuesta.statusCode != 200) {
        if (kDebugMode) debugPrint('IA: HTTP ${respuesta.statusCode}');
        return null;
      }
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (datos is! Map) return null;
      final opciones = datos['choices'];
      if (opciones is! List || opciones.isEmpty) return null;
      final mensaje = opciones.first is Map ? (opciones.first as Map)['message'] : null;
      final contenido = mensaje is Map ? mensaje['content'] : null;
      return contenido is String && contenido.trim().isNotEmpty ? contenido.trim() : null;
    } catch (e) {
      if (kDebugMode) debugPrint('IA: ${e.runtimeType}');
      return null;
    }
  }
}
