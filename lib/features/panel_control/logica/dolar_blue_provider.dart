import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'dolar_blue_provider.g.dart';

/// Cotización del dólar blue en pesos por dólar.
class Cotizacion {
  const Cotizacion({required this.compra, required this.venta});
  final double compra;
  final double venta;
}

/// Cotización del blue desde DolarApi.com (pública, sin clave). Solo se usa
/// para convertir aportes a metas en dólares y para mostrar el patrimonio en
/// dólares: el disponible no depende de ella.
@riverpod
class DolarBlue extends _$DolarBlue {
  static const String _kCompra = 'dolarBlueCompra';
  static const String _kVenta = 'dolarBlueVenta';

  @override
  Future<Cotizacion?> build() async {
    try {
      final respuesta = await http
          .get(Uri.parse('https://dolarapi.com/v1/dolares/blue'))
          .timeout(const Duration(seconds: 10));
      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
        final cotizacion = Cotizacion(
          compra: (datos['compra'] as num).toDouble(),
          venta: (datos['venta'] as num).toDouble(),
        );
        await _guardar(cotizacion);
        return cotizacion;
      }
    } catch (_) {
      // Sin red: se usa la última cotización conocida.
    }
    return _leerGuardada();
  }

  Future<void> _guardar(Cotizacion c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kCompra, c.compra);
    await prefs.setDouble(_kVenta, c.venta);
  }

  Future<Cotizacion?> _leerGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    final compra = prefs.getDouble(_kCompra);
    final venta = prefs.getDouble(_kVenta);
    if (compra == null || venta == null) return null;
    return Cotizacion(compra: compra, venta: venta);
  }
}
