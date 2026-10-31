import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../logica/categorias_provider.dart';
import '../modelo/categoria.dart';

/// Confirma el borrado de una categoría. Si tiene movimientos o planes, pide
/// elegir a qué categoría del mismo tipo pasarlos (por defecto, "Otros").
/// Devuelve true si se borró.
class DialogoBorrarCategoria extends ConsumerStatefulWidget {
  const DialogoBorrarCategoria({super.key, required this.categoria, required this.usos});

  final Categoria categoria;
  final int usos;

  static Future<bool> mostrar(BuildContext context, WidgetRef ref, Categoria categoria) async {
    final usos = await ref.read(categoriasControladorProvider.notifier).usos(categoria);
    if (!context.mounted) return false;
    final borrada = await showDialog<bool>(
      context: context,
      builder: (_) => DialogoBorrarCategoria(categoria: categoria, usos: usos),
    );
    return borrada ?? false;
  }

  @override
  ConsumerState<DialogoBorrarCategoria> createState() => _DialogoBorrarCategoriaState();
}

class _DialogoBorrarCategoriaState extends ConsumerState<DialogoBorrarCategoria> {
  int? _destinoId;
  bool _borrando = false;

  Future<void> _borrar() async {
    setState(() => _borrando = true);
    final ok = await ejecutarConAviso(
      context,
      () => ref.read(categoriasControladorProvider.notifier).eliminar(widget.categoria, reasignarA: _destinoId),
      exito: 'Categoría borrada',
    );
    if (!mounted) return;
    ok ? Navigator.pop(context, true) : setState(() => _borrando = false);
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.categoria;
    final alternativas = (ref.watch(categoriasControladorProvider).valueOrNull ?? const <Categoria>[])
        .where((c) => c.tipo == cat.tipo && c.id != cat.id)
        .toList();
    _destinoId ??= (alternativas.where((c) => c.nombre.toLowerCase().startsWith('otros')).firstOrNull ??
            alternativas.firstOrNull)
        ?.id;
    final necesitaDestino = widget.usos > 0;

    return AlertDialog(
      title: Text('Borrar "${cat.nombre}"', style: TextStyle(color: context.colores.textoPrimario)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            necesitaDestino
                ? 'Tiene ${widget.usos} movimientos o planes. Elegí a qué categoría pasarlos para que los totales no cambien:'
                : 'No tiene movimientos. ¿La borramos?',
            style: TextStyle(color: context.colores.textoSecundario),
          ),
          if (necesitaDestino) ...[
            const SizedBox(height: 12),
            if (alternativas.isEmpty)
              const Text('No hay otra categoría del mismo tipo. Creá una antes de borrar esta.',
                  style: TextStyle(color: TemaApp.rojo))
            else
              DropdownButtonFormField<int>(
                initialValue: _destinoId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Pasar a'),
                items: [
                  for (final c in alternativas) DropdownMenuItem(value: c.id, child: Text(c.nombre)),
                ],
                onChanged: (v) => setState(() => _destinoId = v),
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancelar', style: TextStyle(color: context.colores.textoSecundario)),
        ),
        TextButton(
          onPressed: _borrando || (necesitaDestino && _destinoId == null) ? null : _borrar,
          child: Text(necesitaDestino ? 'Pasar y borrar' : 'Borrar',
              style: const TextStyle(color: TemaApp.rojo, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
