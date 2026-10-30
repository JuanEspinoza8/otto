import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'dolar_blue_provider.g.dart';

/// Provider que obtiene la cotización del dólar blue desde DolarApi.com.
/// API pública, gratuita, sin key. Devuelve compra/venta o null si falla.
@riverpod
class DolarBlue extends _$DolarBlue {
  @override
  FutureOr<Map<String, double>?> build() async {
    return await _obtenerCotizacion();
  }

  static const String _kCompra = 'dolarBlueCompra';
  static const String _kVenta = 'dolarBlueVenta';

  /// Consulta la API de DolarApi.com y parsea la respuesta. Si hay red, cachea
  /// la cotización; si falla, devuelve la última guardada (para no romper el
  /// disponible ni las metas en USD estando sin internet).
  Future<Map<String, double>?> _obtenerCotizacion() async {
    try {
      final respuesta = await http.get(
        Uri.parse('https://dolarapi.com/v1/dolares/blue'),
      ).timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
        final cotizacion = {
          'compra': (datos['compra'] as num).toDouble(),
          'venta': (datos['venta'] as num).toDouble(),
        };
        await _guardarCache(cotizacion);
        return cotizacion;
      }
      return await _leerCache();
    } catch (error) {
      // Sin red: usamos la última cotización conocida en lugar de null.
      return await _leerCache();
    }
  }

  /// Guarda la última cotización válida para poder usarla sin conexión.
  Future<void> _guardarCache(Map<String, double> cotizacion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kCompra, cotizacion['compra']!);
      await prefs.setDouble(_kVenta, cotizacion['venta']!);
    } catch (_) {/* el cache no es crítico */}
  }

  /// Lee la última cotización cacheada (o null si nunca se guardó).
  Future<Map<String, double>?> _leerCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final compra = prefs.getDouble(_kCompra);
      final venta = prefs.getDouble(_kVenta);
      if (compra == null || venta == null) return null;
      return {'compra': compra, 'venta': venta};
    } catch (_) {
      return null;
    }
  }

  /// Fuerza una actualización manual de la cotización.
  Future<void> refrescar() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _obtenerCotizacion());
  }
}
