/// Utilidades de formateo de texto.
library;

/// Devuelve el texto con la primera letra en mayúscula.
String capitalizar(String texto) {
  final t = texto.trim();
  if (t.isEmpty) return t;
  return t[0].toUpperCase() + t.substring(1);
}

/// Texto para comparar nombres: minúsculas, sin acentos ni espacios de más.
String normalizar(String texto) {
  const conAcento = 'áàäâéèëêíìïîóòöôúùüûñ';
  const sinAcento = 'aaaaeeeeiiiioooouuuun';
  final buffer = StringBuffer();
  for (final ch in texto.toLowerCase().trim().split('')) {
    final i = conAcento.indexOf(ch);
    buffer.write(i >= 0 ? sinAcento[i] : ch);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
}
