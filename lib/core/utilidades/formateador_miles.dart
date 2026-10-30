import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatea el texto de un campo numérico al estilo argentino (3.000.000,50):
/// puntos de miles y coma decimal (hasta 2 decimales) a medida que se escribe.
///
/// Los parsers de la app usan [parsearMonto], que entiende este formato.
class FormateadorMiles extends TextInputFormatter {
  final NumberFormat _formatoEntero = NumberFormat.decimalPattern('es_AR');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Nos quedamos sólo con dígitos y una única coma decimal.
    final soloValidos = StringBuffer();
    bool comaUsada = false;
    for (final ch in newValue.text.split('')) {
      if ('0123456789'.contains(ch)) {
        soloValidos.write(ch);
      } else if (ch == ',' && !comaUsada) {
        soloValidos.write(',');
        comaUsada = true;
      }
    }
    final limpio = soloValidos.toString();
    if (limpio.isEmpty) return const TextEditingValue(text: '');

    final idxComa = limpio.indexOf(',');
    final String entero = idxComa >= 0 ? limpio.substring(0, idxComa) : limpio;
    String? decimales = idxComa >= 0 ? limpio.substring(idxComa + 1) : null;
    if (decimales != null && decimales.length > 2) {
      decimales = decimales.substring(0, 2);
    }
    // Evitamos overflow con montos absurdamente grandes.
    if (entero.length > 15) return oldValue;

    final buffer = StringBuffer();
    buffer.write(_formatoEntero.format(entero.isEmpty ? 0 : int.parse(entero)));
    if (idxComa >= 0) {
      buffer.write(',');
      buffer.write(decimales);
    }
    final resultado = buffer.toString();
    return TextEditingValue(
      text: resultado,
      selection: TextSelection.collapsed(offset: resultado.length),
    );
  }
}

/// Convierte el texto de un campo de monto (formato es_AR "1.234,56") a double.
double parsearMonto(String texto) =>
    double.tryParse(texto.replaceAll('.', '').replaceAll(',', '.')) ?? 0;

/// Texto para precargar un campo de monto, mostrando decimales si los tiene.
/// Devuelve '' para montos <= 0 (campo vacío).
String montoEditable(num monto) {
  if (monto <= 0) return '';
  return monto == monto.truncateToDouble()
      ? monto.toStringAsFixed(0)
      : monto.toStringAsFixed(2).replaceAll('.', ',');
}
