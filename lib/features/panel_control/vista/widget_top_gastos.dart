import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/tema/tema_app.dart';
import '../logica/dashboard_provider.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../../categorias/modelo/categoria.dart';

/// Widget que muestra el Top 3 de gastos del mes con barras de progreso.
class WidgetTopGastos extends ConsumerWidget {
  const WidgetTopGastos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gastosCat = ref.watch(gastosPorCategoriaProvider).valueOrNull ?? const <String, double>{};
    final categoriasAsync = ref.watch(categoriasControladorProvider);
    final categorias = categoriasAsync.valueOrNull ?? [];

    final listGastos = gastosCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = listGastos.take(3).toList();
    final double maxGastoTop = top3.isNotEmpty ? top3.first.value : 1.0;

    if (top3.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: TemaApp.rojo, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('TOP 3 GASTOS DEL MES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colores.textoSecundario, letterSpacing: 1.1)),
            ],
          ),
          const SizedBox(height: 16),
          ...top3.map((e) {
            final nombre = e.key.split('|')[0];
            final cat = categorias.firstWhere(
              (c) => c.nombre == nombre,
              orElse: () => Categoria(nombre: nombre, tipo: 'gasto', colorHex: '0xFF9E9E9E', icono: 'help'),
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.category, size: 16, color: Color(int.parse(cat.colorHex))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(nombre, style: TextStyle(fontWeight: FontWeight.bold, color: context.colores.textoPrimario))),
                      Text('\$${NumberFormat('#,##0.##', 'es_AR').format(e.value)}', style: const TextStyle(color: TemaApp.rojo, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.value / maxGastoTop,
                      minHeight: 4,
                      backgroundColor: context.colores.superficieAlta,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(int.parse(cat.colorHex))),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
