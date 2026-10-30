import '../../categorias/modelo/categoria.dart';

/// Nivel de confianza de la interpretación de Monedita.
enum NivelConfianza { alta, media, baja }

/// Resultado de la interpretación de un mensaje por Monedita.
class SugerenciaMonedita {
  final String tipo; // 'ingreso' o 'gasto'
  final double monto;
  final int? categoriaId;
  final String? nombreCategoria;
  final String descripcion;
  final NivelConfianza confianza;

  SugerenciaMonedita({
    required this.tipo,
    required this.monto,
    this.categoriaId,
    this.nombreCategoria,
    required this.descripcion,
    required this.confianza,
  });
}

/// Servicio que interpreta texto libre del usuario y lo convierte en un
/// movimiento sugerido. Usa parsing local con RegExp optimizado para
/// expresiones argentinas cotidianas.
class ServicioMonedita {
  /// Palabras clave que indican un gasto.
  static const _palabrasGasto = [
    'gasté', 'gaste', 'gastamos', 'pagué', 'pague', 'compré', 'compre',
    'me salió', 'me salio', 'me costó', 'me costo', 'gasté en', 'invertí',
    'pago de', 'pago', 'abono', 'saqué', 'saque', 'transferí', 'transferi',
  ];

  /// Palabras clave que indican un ingreso.
  static const _palabrasIngreso = [
    'cobré', 'cobre', 'me pagaron', 'me depositaron', 'vendí', 'vendi',
    'recibí', 'recibi', 'sueldo', 'ingresó', 'ingreso', 'facturé', 'facture',
    'me transfirieron', 'gané', 'gane', 'me dieron',
  ];

  /// Mapa de sinónimos para inferir categorías desde el texto.
  static const Map<String, List<String>> _sinonimosCategoria = {
    'Alimentación': [
      'super', 'supermercado', 'carrefour', 'coto', 'dia', 'jumbo', 'vea',
      'chino', 'verdulería', 'verduleria', 'carnicería', 'carniceria',
      'almacén', 'almacen', 'comida', 'restaurante', 'delivery', 'pedidos ya',
      'rappi', 'mcdonalds', 'burger', 'pizza', 'café', 'cafe', 'bar',
      'almuerzo', 'cena', 'desayuno', 'merienda', 'kiosco',
    ],
    'Transporte': [
      'uber', 'cabify', 'taxi', 'remis', 'colectivo', 'subte', 'tren',
      'nafta', 'combustible', 'estacionamiento', 'peaje', 'gnc', 'ypf',
      'shell', 'axion', 'auto', 'mecánico', 'mecanico', 'gomería', 'gomeria',
    ],
    'Sueldo': [
      'sueldo', 'salario', 'quincena', 'liquidación', 'liquidacion',
      'aguinaldo', 'bono', 'premio',
    ],
    'Servicios': [
      'luz', 'gas', 'agua', 'internet', 'teléfono', 'telefono', 'celular',
      'cable', 'edenor', 'edesur', 'metrogas', 'telecom', 'personal',
      'claro', 'movistar', 'flow', 'spotify', 'netflix', 'youtube',
    ],
    'Vivienda': [
      'alquiler', 'expensas', 'inmobiliaria', 'departamento', 'casa',
      'renta', 'ABL',
    ],
    'Salud': [
      'farmacia', 'médico', 'medico', 'hospital', 'clínica', 'clinica',
      'obra social', 'prepaga', 'osde', 'swiss', 'galeno', 'remedios',
    ],
    'Entretenimiento': [
      'cine', 'teatro', 'recital', 'show', 'boliche', 'salida',
      'juego', 'steam', 'play', 'xbox', 'nintendo',
    ],
    'Deudas': [
      'cuota', 'préstamo', 'prestamo', 'deuda', 'tarjeta', 'visa',
      'mastercard', 'american', 'crédito', 'credito',
    ],
    'Otros Gastos': [
      'regalo', 'ropa', 'zapatillas', 'shopping', 'compra', 'online',
      'mercadolibre', 'amazon',
    ],
  };

  /// Interpreta un mensaje libre del usuario y devuelve una sugerencia.
  static SugerenciaMonedita? interpretar(String mensaje, List<Categoria> categorias) {
    if (mensaje.trim().isEmpty) return null;

    final textoLimpio = mensaje.toLowerCase().trim();

    // 1. Detectar tipo (gasto o ingreso)
    final tipo = _detectarTipo(textoLimpio);

    // 2. Extraer monto
    final monto = _extraerMonto(textoLimpio);
    if (monto == null || monto <= 0) return null;

    // 3. Inferir categoría
    final categoriaInferida = _inferirCategoria(textoLimpio, categorias);

    // 4. Generar descripción limpia
    final descripcion = _limpiarDescripcion(textoLimpio);

    // 5. Calcular confianza
    NivelConfianza confianza;
    if (monto > 0 && categoriaInferida != null) {
      confianza = NivelConfianza.alta;
    } else if (monto > 0) {
      confianza = NivelConfianza.media;
    } else {
      confianza = NivelConfianza.baja;
    }

    return SugerenciaMonedita(
      tipo: tipo,
      monto: monto,
      categoriaId: categoriaInferida?.id,
      nombreCategoria: categoriaInferida?.nombre,
      descripcion: descripcion,
      confianza: confianza,
    );
  }

  /// Fallback local multi-movimiento: parte la frase por conectores y procesa
  /// cada fragmento por separado.
  static List<SugerenciaMonedita> interpretarMulti(String mensaje, List<Categoria> categorias) {
    final fragmentos = mensaje.split(RegExp(r'\s+y\s+|,|;', caseSensitive: false));
    final resultado = <SugerenciaMonedita>[];
    for (final f in fragmentos) {
      final s = interpretar(f, categorias);
      if (s != null) resultado.add(s);
    }
    if (resultado.isEmpty) {
      final s = interpretar(mensaje, categorias);
      if (s != null) resultado.add(s);
    }
    return resultado;
  }

  /// Detecta si el mensaje es un ingreso o un gasto.
  static String _detectarTipo(String texto) {
    for (final palabra in _palabrasIngreso) {
      if (texto.contains(palabra)) return 'ingreso';
    }
    // Por defecto asumimos gasto (es lo más común)
    return 'gasto';
  }

  /// Extrae el monto numérico del texto.
  /// Soporta: $25.000 / 25000 / 25 mil / 25k / 25 lucas / 2 palos / 1.500,50
  ///
  /// El orden importa: primero "mil/lucas/k/palo" (porque "5 lucas" no debe
  /// quedar en 5), después el formato con puntos de miles, y por último un
  /// número plano (que sí puede tener más de 3 dígitos seguidos).
  static double? _extraerMonto(String texto) {
    // 1) "25 mil" / "25mil" / "25 lucas" / "25k" / "2 palos" (millón)
    final regexMil = RegExp(r'(\d+(?:[.,]\d+)?)\s*(mil|lucas?|k|palos?)\b');
    final mMil = regexMil.firstMatch(texto);
    if (mMil != null) {
      final n = double.tryParse(mMil.group(1)!.replaceAll('.', '').replaceAll(',', '.'));
      if (n != null && n > 0) {
        final factor = mMil.group(2)!.startsWith('palo') ? 1000000.0 : 1000.0;
        return n * factor;
      }
    }

    // 2) Formato con separador de miles: 25.000 / 1.500.000 / 1.500,50
    final regexMiles = RegExp(r'\$?\s*(\d{1,3}(?:\.\d{3})+(?:,\d{1,2})?)');
    final mMiles = regexMiles.firstMatch(texto);
    if (mMiles != null) {
      final v = double.tryParse(mMiles.group(1)!.replaceAll('.', '').replaceAll(',', '.'));
      if (v != null && v > 0) return v;
    }

    // 3) Número plano: 300000 / 300000,50 / $5000
    final regexPlano = RegExp(r'\$?\s*(\d+(?:,\d{1,2})?)');
    final mPlano = regexPlano.firstMatch(texto);
    if (mPlano != null) {
      final v = double.tryParse(mPlano.group(1)!.replaceAll(',', '.'));
      if (v != null && v > 0) return v;
    }

    return null;
  }

  /// Infiere la categoría más probable buscando sinónimos en el texto.
  static Categoria? _inferirCategoria(String texto, List<Categoria> categorias) {
    // Primero buscamos coincidencia directa con nombres de categorías existentes
    for (final cat in categorias) {
      if (texto.contains(cat.nombre.toLowerCase())) {
        return cat;
      }
    }

    // Luego buscamos por sinónimos
    String? nombreCategoriaInferida;
    int mayorCoincidencias = 0;

    for (final entry in _sinonimosCategoria.entries) {
      int coincidencias = 0;
      for (final sinonimo in entry.value) {
        if (texto.contains(sinonimo.toLowerCase())) {
          coincidencias++;
        }
      }
      if (coincidencias > mayorCoincidencias) {
        mayorCoincidencias = coincidencias;
        nombreCategoriaInferida = entry.key;
      }
    }

    if (nombreCategoriaInferida != null) {
      // Buscamos la categoría real por nombre
      try {
        return categorias.firstWhere(
          (c) => c.nombre.toLowerCase() == nombreCategoriaInferida!.toLowerCase(),
        );
      } catch (_) {
        // Si no existe esa categoría en la BD, retornamos null
        return null;
      }
    }

    return null;
  }

  /// Genera una descripción limpia del movimiento a partir del texto.
  static String _limpiarDescripcion(String texto) {
    // Quitar indicadores de monto y tipo para dejar solo la descripción
    String limpio = texto;
    
    // Quitar montos (con o sin $, con o sin "mil/lucas/k/palo")
    limpio = limpio.replaceAll(RegExp(r'\d[\d\.,]*\s*(?:mil|lucas?|k|palos?)\b'), '');
    limpio = limpio.replaceAll(RegExp(r'\$?\s*\d[\d\.,]*'), '');
    
    // Quitar palabras clave de tipo
    for (final palabra in [..._palabrasGasto, ..._palabrasIngreso]) {
      limpio = limpio.replaceAll(palabra, '');
    }
    
    // Quitar preposiciones sueltas y espacios extra
    limpio = limpio.replaceAll(RegExp(r'\b(en|de|por|el|la|los|las|un|una|me|le)\b'), '');
    limpio = limpio.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Si queda algo, capitalizar primera letra
    if (limpio.isNotEmpty) {
      limpio = limpio[0].toUpperCase() + limpio.substring(1);
    } else {
      limpio = texto[0].toUpperCase() + texto.substring(1);
    }
    
    return limpio;
  }
}
