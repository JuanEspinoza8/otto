import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categorias/logica/categorias_provider.dart';
import '../../categorias/modelo/categoria.dart';
import '../modelo/plan.dart';

/// Categoría de un gasto fijo o una cuota. Si el plan no tiene categoría
/// propia, aparece elegida la que va a usar al confirmarse ("Otros Gastos" o
/// "Deudas"), en vez de una opción aparte con el mismo nombre.
class SelectorCategoriaPlan extends ConsumerWidget {
  const SelectorCategoriaPlan({super.key, required this.tipo, required this.categoriaId, required this.alCambiar});

  final TipoPlan tipo;
  final int? categoriaId;
  final ValueChanged<int> alCambiar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categorias = (ref.watch(categoriasControladorProvider).valueOrNull ?? [])
        .where((c) => c.tipo == 'gasto')
        .toList();
    final elegida = categorias.any((c) => c.id == categoriaId) ? categoriaId : _porDefecto(categorias)?.id;

    return DropdownButtonFormField<int>(
      // Se recrea cuando cambia la elegida (por ejemplo, al llegar las
      // categorías), porque initialValue se lee una sola vez.
      key: ValueKey(elegida),
      initialValue: elegida,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Categoría'),
      items: [for (final c in categorias) DropdownMenuItem(value: c.id, child: Text(c.nombre))],
      onChanged: (id) {
        if (id != null) alCambiar(id);
      },
    );
  }

  /// La misma que elige ServicioPlanes.categoriaPara.
  Categoria? _porDefecto(List<Categoria> categorias) {
    final nombre = tipo.categoriaPorDefecto;
    return categorias.where((c) => c.nombre.toLowerCase() == nombre).firstOrNull ??
        categorias.where((c) => c.nombre.toLowerCase().startsWith('otros')).firstOrNull ??
        categorias.firstOrNull;
  }
}
