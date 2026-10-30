import '../../../features/categorias/modelo/categoria.dart';
import '../../../features/movimientos/modelo/movimiento.dart';
import '../../../features/panel_control/modelo/meta.dart';

/// Devuelve la categoría "visual" con la que se muestra un movimiento en las
/// listas. Los aportes de ahorro no tienen categoría real: se representan con
/// el nombre de la meta destino, en azul y con ícono de alcancía.
Categoria categoriaDeMovimiento(
  Movimiento m,
  List<Categoria> categorias,
  Iterable<Meta> metas,
) {
  if (m.esAhorro) {
    final meta = metas.where((x) => x.id == m.metaId);
    return Categoria(
      nombre: meta.isNotEmpty ? meta.first.nombre : 'Ahorro',
      tipo: 'ahorro',
      colorHex: '0xFF3B82F6',
      icono: meta.isNotEmpty ? meta.first.icono : 'savings',
    );
  }
  final coincide = categorias.where((c) => c.id == m.categoriaId);
  return coincide.isNotEmpty
      ? coincide.first
      : Categoria(nombre: 'Otros', tipo: m.tipo, colorHex: '0xFF9E9E9E', icono: 'category');
}
