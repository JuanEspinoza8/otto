import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tema/tema_app.dart';
import '../logica/categorias_provider.dart';
import '../modelo/categoria.dart';

class SeccionMisCategorias extends ConsumerStatefulWidget {
  const SeccionMisCategorias({super.key});

  @override
  ConsumerState<SeccionMisCategorias> createState() => _SeccionMisCategoriasState();
}

class _SeccionMisCategoriasState extends ConsumerState<SeccionMisCategorias> {
  final _controladorNombre = TextEditingController();
  String _tipoNuevo = 'ingreso';

  @override
  void dispose() {
    _controladorNombre.dispose();
    super.dispose();
  }

  void _agregarCategoria() {
    if (_controladorNombre.text.trim().isEmpty) return;
    
    final nuevaCat = Categoria(
      nombre: _controladorNombre.text.trim(),
      tipo: _tipoNuevo,
      colorHex: _tipoNuevo == 'ingreso' ? '0xFF4CAF50' : '0xFFFF9800', // Verde o Naranja base
      icono: _tipoNuevo == 'ingreso' ? 'monetization_on' : 'shopping_cart',
    );

    ref.read(categoriasControladorProvider.notifier).agregarCategoria(nuevaCat);
    _controladorNombre.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriasControladorProvider);
    final categorias = categoriasAsync.valueOrNull ?? [];

    final ingresos = categorias.where((c) => c.tipo == 'ingreso').toList();
    final gastos = categorias.where((c) => c.tipo == 'gasto').toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colores.superficie,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colores.borde),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: TemaApp.verde, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Mis categorías',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colores.textoPrimario),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Chips de Ingresos
            Text('INGRESOS', style: TextStyle(fontSize: 12, color: context.colores.textoSecundario)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ingresos.map((c) => Chip(
                label: Text(c.nombre),
                backgroundColor: context.colores.superficieAlta,
                side: BorderSide.none,
              )).toList(),
            ),

            const SizedBox(height: 16),

            // Chips de Gastos
            Text('GASTOS', style: TextStyle(fontSize: 12, color: context.colores.textoSecundario)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: gastos.map((c) => Chip(
                label: Text(c.nombre),
                backgroundColor: context.colores.superficieAlta,
                side: BorderSide.none,
              )).toList(),
            ),

            const SizedBox(height: 24),
            
            // Formulario de Nueva Categoría
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _controladorNombre,
                  decoration: const InputDecoration(
                    hintText: 'Nueva categoría...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _tipoNuevo,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ingreso', child: Text('Ingreso')),
                    DropdownMenuItem(value: 'gasto', child: Text('Gasto')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _tipoNuevo = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _agregarCategoria,
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaApp.verde,
                foregroundColor: Colors.white,
              ),
              child: const Text('+ Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}
