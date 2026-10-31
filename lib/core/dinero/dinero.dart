/// Monedas que maneja la app.
enum Moneda {
  ars('ARS', r'$'),
  usd('USD', r'US$');

  const Moneda(this.codigo, this.simbolo);

  /// Código que se guarda en la base ('ARS' o 'USD').
  final String codigo;
  final String simbolo;

  static Moneda desdeCodigo(String? codigo) =>
      codigo == 'USD' ? Moneda.usd : Moneda.ars;
}

/// Cantidad de dinero en centavos enteros, con su moneda.
///
/// Es el único lugar de la app que convierte texto en montos y montos en
/// texto (formato es_AR: punto de miles y coma decimal).
class Dinero implements Comparable<Dinero> {
  const Dinero(this.centavos, [this.moneda = Moneda.ars]);

  const Dinero.cero([this.moneda = Moneda.ars]) : centavos = 0;

  /// Desde unidades (pesos o dólares), redondeando al centavo.
  factory Dinero.desdeUnidades(num unidades, [Moneda moneda = Moneda.ars]) =>
      Dinero((unidades * 100).round(), moneda);

  final int centavos;
  final Moneda moneda;

  /// Tope de dígitos enteros que se aceptan al parsear (evita desbordes).
  static const int maxDigitosEnteros = 15;
  static const int _maxCentavos = 99999999999999999; // 15 dígitos + 2 decimales

  double get unidades => centavos / 100;
  bool get esCero => centavos == 0;
  bool get esPositivo => centavos > 0;
  bool get esNegativo => centavos < 0;

  Dinero operator +(Dinero otro) {
    _mismaMoneda(otro);
    return Dinero(centavos + otro.centavos, moneda);
  }

  Dinero operator -(Dinero otro) {
    _mismaMoneda(otro);
    return Dinero(centavos - otro.centavos, moneda);
  }

  Dinero operator -() => Dinero(-centavos, moneda);

  /// Multiplica por un factor (por ejemplo, horas × valor de la hora),
  /// redondeando al centavo.
  Dinero por(num factor) => Dinero((centavos * factor).round(), moneda);

  bool operator >(Dinero otro) => compareTo(otro) > 0;
  bool operator >=(Dinero otro) => compareTo(otro) >= 0;
  bool operator <(Dinero otro) => compareTo(otro) < 0;
  bool operator <=(Dinero otro) => compareTo(otro) <= 0;

  Dinero min(Dinero otro) => this <= otro ? this : otro;
  Dinero max(Dinero otro) => this >= otro ? this : otro;

  /// Qué porcentaje de [total] es este monto, truncado y calculado con
  /// enteros: 116.000 de 100.000 da 116 (en coma flotante 1,16 × 100 da
  /// 115,99…). 0 si [total] no es positivo.
  int porcentajeDe(Dinero total) {
    _mismaMoneda(total);
    if (!total.esPositivo) return 0;
    return centavos * 100 ~/ total.centavos;
  }

  /// Convierte a [destino] con una [cotizacion] expresada en pesos por dólar.
  Dinero convertir(Moneda destino, double cotizacion) {
    if (destino == moneda) return this;
    if (cotizacion <= 0) {
      throw ArgumentError.value(cotizacion, 'cotizacion', 'debe ser positiva');
    }
    final valor = moneda == Moneda.ars ? centavos / cotizacion : centavos * cotizacion;
    return Dinero(valor.round(), destino);
  }

  @override
  int compareTo(Dinero otro) {
    _mismaMoneda(otro);
    return centavos.compareTo(otro.centavos);
  }

  @override
  bool operator ==(Object other) =>
      other is Dinero && other.centavos == centavos && other.moneda == moneda;

  @override
  int get hashCode => Object.hash(centavos, moneda);

  void _mismaMoneda(Dinero otro) {
    if (otro.moneda != moneda) {
      throw ArgumentError('No se pueden operar ${moneda.codigo} y ${otro.moneda.codigo}');
    }
  }

  /// Texto para mostrar: `$1.234`, `$1.234,50`, `-US$300`.
  ///
  /// Con [simbolo] en false devuelve solo el número. Con [abreviado] usa
  /// K (miles) y M (millones) para tarjetas chicas: `$850K`, `$1,5M`.
  String formatear({bool simbolo = true, bool abreviado = false}) {
    final signo = centavos < 0 ? '-' : '';
    final prefijo = simbolo ? moneda.simbolo : '';
    final absoluto = centavos.abs();
    if (abreviado && absoluto >= 100000000) {
      return '$signo$prefijo${_abreviar(absoluto / 100000000, 'M')}';
    }
    if (abreviado && absoluto >= 100000) {
      return '$signo$prefijo${_abreviar(absoluto / 100000, 'K')}';
    }
    return '$signo$prefijo${_numero(absoluto)}';
  }

  /// Texto para precargar un campo editable (sin símbolo). Vacío si es cero.
  String get textoEditable => centavos <= 0 ? '' : _numero(centavos);

  static String _abreviar(double valor, String sufijo) {
    final redondeado = (valor * 10).floor() / 10;
    final texto = redondeado == redondeado.truncateToDouble()
        ? redondeado.toStringAsFixed(0)
        : redondeado.toStringAsFixed(1).replaceAll('.', ',');
    return '$texto$sufijo';
  }

  static String _numero(int centavosAbs) {
    final enteros = centavosAbs ~/ 100;
    final resto = centavosAbs % 100;
    final texto = agruparMiles(enteros);
    return resto == 0 ? texto : '$texto,${resto.toString().padLeft(2, '0')}';
  }

  /// `1234567` → `1.234.567`.
  static String agruparMiles(int entero) {
    final digitos = entero.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digitos[i]);
    }
    return buffer.toString();
  }

  /// Interpreta un monto escrito por el usuario o dictado en el chat.
  ///
  /// Acepta `$`, `US$`, puntos de miles y coma decimal (`1.234,56`), un punto
  /// como decimal si lo siguen 1 o 2 dígitos (`1500.50`, `1.5`) y sufijos
  /// coloquiales: `mil`, `k`, `luca(s)` (×1.000) y `palo(s)` (×1.000.000).
  ///
  /// Devuelve null si el texto está vacío, es negativo, no es un número o
  /// supera [maxDigitosEnteros] dígitos.
  static Dinero? parsear(String texto, {Moneda moneda = Moneda.ars}) {
    var t = texto.trim().toLowerCase();
    if (t.isEmpty || t.startsWith('-')) return null;
    t = t.replaceAll('us\$', '').replaceAll('\$', '').replaceAll(' ', '');

    var multiplicador = 1;
    final sufijo = RegExp(r'(mil|k|lucas?|palos?)$').firstMatch(t);
    if (sufijo != null) {
      multiplicador = sufijo.group(1)!.startsWith('palo') ? 1000000 : 1000;
      t = t.substring(0, sufijo.start);
    }

    final centesimos = parsearCentesimos(t);
    if (centesimos == null) return null;
    final centavos = centesimos * multiplicador;
    if (centavos > _maxCentavos) return null;
    return Dinero(centavos, moneda);
  }

  @override
  String toString() => formatear();
}

/// Interpreta un número es_AR y lo devuelve en centésimos (`1.234,5` →
/// 123450). Sirve para montos y también para cantidades como horas.
///
/// Reglas para el punto: si hay varios, o uno solo seguido de exactamente 3
/// dígitos, es separador de miles (`150.000`); si lo siguen 1 o 2 dígitos es
/// decimal (`1500.50`). La coma siempre es decimal. Más de 2 decimales o más
/// de [Dinero.maxDigitosEnteros] dígitos enteros devuelve null.
int? parsearCentesimos(String texto) {
  final t = texto.trim();
  if (!RegExp(r'^[0-9.,]+$').hasMatch(t) || !RegExp(r'\d').hasMatch(t)) return null;

  String entero;
  String decimales = '';
  final comas = ','.allMatches(t).length;
  final puntos = '.'.allMatches(t).length;

  if (comas > 1) return null;
  if (comas == 1) {
    final partes = t.split(',');
    entero = partes[0];
    decimales = partes[1];
    if (!_milesValidos(entero)) return null;
    entero = entero.replaceAll('.', '');
  } else if (puntos == 1) {
    final partes = t.split('.');
    if (partes[1].length == 3) {
      if (partes[0].length > 3) return null;
      entero = partes[0] + partes[1];
    } else {
      entero = partes[0];
      decimales = partes[1];
    }
  } else {
    if (puntos > 1 && !_milesValidos(t)) return null;
    entero = t.replaceAll('.', '');
  }

  if (decimales.length > 2) return null;
  if (entero.isEmpty) entero = '0';
  if (entero.length > Dinero.maxDigitosEnteros) return null;

  final parteEntera = int.tryParse(entero);
  final parteDecimal = decimales.isEmpty ? 0 : int.tryParse(decimales.padRight(2, '0'));
  if (parteEntera == null || parteDecimal == null) return null;
  return parteEntera * 100 + parteDecimal;
}

/// Grupos de miles bien formados: `1.234.567` sí, `12.34` no.
bool _milesValidos(String entero) {
  if (!entero.contains('.')) return true;
  return RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(entero);
}
