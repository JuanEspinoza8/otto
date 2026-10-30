import 'package:flutter/material.dart';

/// Utilidad para mapear los nombres de iconos guardados en la base de datos 
/// (como texto) a la clase IconData de Flutter para renderizarlos.
class MapeadorIconos {
  static const Map<String, IconData> _mapa = {
    'attach_money': Icons.attach_money,
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'more_horiz': Icons.more_horiz,
    'shopping_cart': Icons.shopping_cart,
    'local_hospital': Icons.local_hospital,
    'school': Icons.school,
    'home': Icons.home,
    'flight': Icons.flight,
    'pets': Icons.pets,
    'fitness_center': Icons.fitness_center,
    'category': Icons.category,
    'electric_bolt': Icons.electric_bolt,
    'videogame_asset': Icons.videogame_asset,
    'local_cafe': Icons.local_cafe,
    'more_time': Icons.more_time,
    'savings': Icons.savings,
    'monetization_on': Icons.monetization_on,
  };

  /// Devuelve el IconData correspondiente, o un ícono genérico por defecto si no existe.
  static IconData obtenerIcono(String nombre) {
    return _mapa[nombre] ?? Icons.category;
  }

  /// Retorna la lista de todas las claves (nombres de íconos) disponibles para el selector.
  static List<String> obtenerNombresDisponibles() {
    return _mapa.keys.toList();
  }
}
