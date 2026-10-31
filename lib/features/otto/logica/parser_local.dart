import '../../../core/dinero/dinero.dart';
import '../../categorias/modelo/categoria.dart';
import 'sugerencia_otto.dart';

/// Interpreta mensajes sin IA ("gasté 5 lucas en el super"). Es el respaldo
/// cuando la IA está apagada, sin configurar o no responde.
class ParserLocal {
  static const _palabrasGasto = [
    'gasté', 'gaste', 'gastamos', 'pagué', 'pague', 'compré', 'compre',
    'me salió', 'me salio', 'me costó', 'me costo', 'invertí', 'inverti',
    'pago de', 'abono', 'saqué', 'saque', 'transferí', 'transferi',
  ];

  static const _palabrasIngreso = [
    'cobré', 'cobre', 'me pagaron', 'me depositaron', 'vendí', 'vendi',
    'recibí', 'recibi', 'sueldo', 'ingresó', 'ingreso', 'facturé', 'facture',
    'me transfirieron', 'gané', 'gane', 'me dieron', 'horas extra',
  ];

  static const Map<String, List<String>> _sinonimos = {
    'Alimentación': [
      'super', 'supermercado', 'carrefour', 'coto', 'jumbo', 'verdulería', 'verduleria',
      'carnicería', 'carniceria', 'almacén', 'almacen', 'comida', 'restaurante', 'delivery',
      'pedidos ya', 'rappi', 'pizza', 'café', 'cafe', 'almuerzo', 'cena', 'desayuno', 'kiosco',
    ],
    'Transporte': [
      'uber', 'cabify', 'taxi', 'remis', 'colectivo', 'subte', 'tren', 'nafta',
      'combustible', 'estacionamiento', 'peaje', 'gnc', 'mecánico', 'mecanico',
    ],
    'Sueldo': ['sueldo', 'salario', 'quincena', 'aguinaldo'],
    'Servicios': [
      'luz', 'gas', 'agua', 'internet', 'teléfono', 'telefono', 'celular', 'cable',
      'edenor', 'edesur', 'metrogas', 'spotify', 'netflix', 'youtube',
    ],
    'Vivienda': ['alquiler', 'expensas', 'inmobiliaria', 'abl'],
    'Salud': ['farmacia', 'médico', 'medico', 'clínica', 'clinica', 'obra social', 'prepaga', 'remedios'],
    'Entretenimiento': ['cine', 'teatro', 'recital', 'boliche', 'steam', 'juego'],
    'Deudas': ['cuota', 'préstamo', 'prestamo', 'deuda', 'tarjeta'],
    'Horas extras': ['horas extra'],
  };

  /// Un monto: número con sufijo (mil, k, luca, palo), con `$`, o suelto.
  static final _monto = RegExp(
    r'(\$\s*)?(\d[\d.,]*)\s*(mil\b|k\b|lucas?\b|palos?\b)?',
    caseSensitive: false,
  );
  static final _horas = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:h\b|hs\b|horas?\b)', caseSensitive: false);

  /// Varios movimientos en una frase, separados por "y", comas o punto y coma.
  static List<SugerenciaOtto> interpretar(String mensaje, List<Categoria> categorias) {
    final fragmentos = mensaje.split(RegExp(r'\s+y\s+|,(?!\d)|;', caseSensitive: false));
    final resultado = fragmentos
        .map((f) => _interpretarUno(f, categorias))
        .whereType<SugerenciaOtto>()
        .toList();
    if (resultado.isEmpty) {
      final entero = _interpretarUno(mensaje, categorias);
      if (entero != null) resultado.add(entero);
    }
    return resultado;
  }

  static SugerenciaOtto? _interpretarUno(String mensaje, List<Categoria> categorias) {
    final texto = mensaje.toLowerCase().trim();
    if (texto.isEmpty) return null;

    final monto = extraerMonto(texto);
    if (monto == null || !monto.esPositivo) return null;
    final tipo = _tipo(texto);
    final categoria = _categoria(texto, categorias, tipo);
    final horas = _horas.firstMatch(texto);

    return SugerenciaOtto(
      tipo: tipo,
      monto: monto,
      descripcion: _descripcion(texto),
      categoriaId: categoria?.id,
      horas: horas == null ? null : (parsearCentesimos(horas.group(1)!) ?? 0) / 100,
    );
  }

  /// El monto del mensaje. Gana el que tiene una pista de que es plata
  /// (`$`, "mil", "lucas", "k", "palo"); si no hay, el número más grande
  /// ("pagué 2 cuotas de 15000" son $15.000, no $2).
  static Dinero? extraerMonto(String texto) {
    Dinero? conPista;
    Dinero? mayor;
    for (final m in _monto.allMatches(texto)) {
      final numero = m.group(2)!.replaceAll(RegExp(r'[.,]$'), '');
      final sufijo = m.group(3) ?? '';
      final valor = Dinero.parsear('$numero$sufijo');
      if (valor == null) continue;
      if (m.group(1) != null || sufijo.isNotEmpty) {
        conPista ??= valor;
      } else if (mayor == null || valor > mayor) {
        mayor = valor;
      }
    }
    return conPista ?? mayor;
  }

  /// Gasto por defecto; ingreso si hay más palabras de ingreso que de gasto.
  static String _tipo(String texto) {
    final gasto = _palabrasGasto.where(texto.contains).length;
    final ingreso = _palabrasIngreso.where(texto.contains).length;
    return ingreso > gasto ? 'ingreso' : 'gasto';
  }

  /// Categoría del mismo tipo: primero por nombre, después por sinónimos.
  static Categoria? _categoria(String texto, List<Categoria> categorias, String tipo) {
    final delTipo = categorias.where((c) => c.tipo == tipo).toList();
    for (final c in delTipo) {
      if (texto.contains(c.nombre.toLowerCase())) return c;
    }
    String? mejor;
    var coincidencias = 0;
    for (final entrada in _sinonimos.entries) {
      final n = entrada.value.where(texto.contains).length;
      if (n > coincidencias) {
        coincidencias = n;
        mejor = entrada.key;
      }
    }
    if (mejor == null) return null;
    return delTipo.where((c) => c.nombre.toLowerCase() == mejor!.toLowerCase()).firstOrNull;
  }

  static String _descripcion(String texto) {
    var limpio = texto.replaceAll(_monto, ' ').replaceAll(_horas, ' ');
    for (final palabra in [..._palabrasGasto, ..._palabrasIngreso]) {
      limpio = limpio.replaceAll(palabra, ' ');
    }
    limpio = limpio
        .replaceAll(RegExp(r'\b(en|de|del|por|el|la|los|las|un|una|me|le|con|para)\b'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (limpio.isEmpty) limpio = texto;
    return limpio[0].toUpperCase() + limpio.substring(1);
  }
}
