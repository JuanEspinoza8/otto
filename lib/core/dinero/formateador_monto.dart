import 'package:flutter/services.dart';

import 'dinero.dart';

/// Formatea un campo de monto al estilo argentino (3.000.000,50) mientras se
/// escribe: puntos de miles y coma decimal, con hasta 2 decimales.
///
/// Los puntos de miles los pone este formateador, así que un punto que el
/// usuario escribe se toma como separador decimal (muchos teclados numéricos
/// solo tienen '.'). Un texto pegado se interpreta con [Dinero.parsear].
class FormateadorMonto extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue anterior, TextEditingValue nuevo) {
    var texto = nuevo.text;

    final cursor = nuevo.selection.baseOffset;
    final escribioUnCaracter = texto.length == anterior.text.length + 1;
    if (escribioUnCaracter && cursor > 0 && cursor <= texto.length && texto[cursor - 1] == '.') {
      texto = '${texto.substring(0, cursor - 1)},${texto.substring(cursor)}';
    } else if (texto.length > anterior.text.length + 1) {
      final pegado = Dinero.parsear(texto);
      if (pegado != null) texto = _conDecimales(pegado);
    }

    // Nos quedamos solo con dígitos y una única coma decimal.
    final soloValidos = StringBuffer();
    var comaUsada = false;
    for (final ch in texto.split('')) {
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
    var entero = idxComa >= 0 ? limpio.substring(0, idxComa) : limpio;
    String? decimales = idxComa >= 0 ? limpio.substring(idxComa + 1) : null;
    if (decimales != null && decimales.length > 2) decimales = decimales.substring(0, 2);

    entero = entero.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (entero.length > Dinero.maxDigitosEnteros) return anterior;

    final resultado = StringBuffer(Dinero.agruparMiles(int.parse(entero.isEmpty ? '0' : entero)));
    if (decimales != null) resultado.write(',$decimales');
    final textoFinal = resultado.toString();
    return TextEditingValue(
      text: textoFinal,
      selection: TextSelection.collapsed(offset: textoFinal.length),
    );
  }

  /// Representación editable que conserva los decimales aunque sean cero
  /// solo si el monto los tiene.
  static String _conDecimales(Dinero d) => d.formatear(simbolo: false);
}
