/// Utilidades de formateo de texto.
library;

/// Devuelve el texto con la primera letra en mayúscula.
String capitalizar(String texto) {
  final t = texto.trim();
  if (t.isEmpty) return t;
  return t[0].toUpperCase() + t.substring(1);
}
