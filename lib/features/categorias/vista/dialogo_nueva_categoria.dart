import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../../../core/utilidades/mapeador_iconos.dart';
import '../logica/categorias_provider.dart';
import '../modelo/categoria.dart';

/// Diálogo rápido para crear una categoría desde la pantalla de registro.
/// Devuelve el id de la categoría creada (o null si se canceló).
class DialogoNuevaCategoria extends ConsumerStatefulWidget {
  final String tipo; // 'gasto' o 'ingreso'
  const DialogoNuevaCategoria({super.key, required this.tipo});

  static Future<int?> mostrar(BuildContext context, String tipo) {
    return showDialog<int>(
      context: context,
      builder: (_) => DialogoNuevaCategoria(tipo: tipo),
    );
  }

  @override
  ConsumerState<DialogoNuevaCategoria> createState() => _DialogoNuevaCategoriaState();
}

class _DialogoNuevaCategoriaState extends ConsumerState<DialogoNuevaCategoria> {
  final _nombre = TextEditingController();
  String _icono = 'category';
  String _colorHex = '0xFF2196F3';

  static const List<String> _colores = [
    '0xFFF44336', '0xFFE91E63', '0xFF9C27B0', '0xFF3F51B5',
    '0xFF2196F3', '0xFF00BCD4', '0xFF009688', '0xFF4CAF50',
    '0xFF8BC34A', '0xFFFFC107', '0xFFFF9800', '0xFF795548',
  ];

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá un nombre para la categoría')),
      );
      return;
    }
    int? id;
    final ok = await ejecutarConAviso(context, () async {
      id = await ref.read(categoriasControladorProvider.notifier).agregar(
            Categoria(nombre: nombre, tipo: widget.tipo, colorHex: _colorHex, icono: _icono),
          );
    });
    if (ok && mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(_colorHex));
    final iconos = MapeadorIconos.obtenerNombresDisponibles();

    return AlertDialog(
      title: Text(
        widget.tipo == 'ingreso' ? 'Nueva categoría de ingreso' : 'Nueva categoría de gasto',
        style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nombre,
              style: TextStyle(color: context.colores.textoPrimario),
              decoration: const InputDecoration(hintText: 'Nombre (ej: Gimnasio)'),
            ),
            const SizedBox(height: 16),
            Text('Ícono', style: TextStyle(color: context.colores.textoSecundario, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: iconos.map((nombre) {
                final sel = _icono == nombre;
                return GestureDetector(
                  onTap: () => setState(() => _icono = nombre),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sel ? color.withValues(alpha: 0.2) : context.colores.superficieAlta,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? color : Colors.transparent, width: 2),
                    ),
                    child: Icon(MapeadorIconos.obtenerIcono(nombre), size: 20, color: sel ? color : context.colores.textoSecundario),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Color', style: TextStyle(color: context.colores.textoSecundario, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colores.map((c) {
                final sel = _colorHex == c;
                return GestureDetector(
                  onTap: () => setState(() => _colorHex = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(int.parse(c)),
                      shape: BoxShape.circle,
                      border: sel ? Border.all(color: context.colores.textoPrimario, width: 3) : null,
                    ),
                    child: sel ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: context.colores.textoSecundario)),
        ),
        ElevatedButton(
          onPressed: _crear,
          style: ElevatedButton.styleFrom(backgroundColor: TemaApp.verde, foregroundColor: Colors.white),
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
