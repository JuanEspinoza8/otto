import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/utilidades/mapeador_iconos.dart';
import '../logica/dashboard_provider.dart';


/// Widget que muestra el Top 3 de gastos del mes con barras de progreso.
class WidgetTopGastos extends ConsumerWidget {
  const WidgetTopGastos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranking = ref.watch(rankingGastosProvider).valueOrNull ?? const <TotalCategoria>[];
    final top3 = ranking.take(3).toList();
    final maxGastoTop = top3.isNotEmpty ? top3.first.total.centavos : 1;

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
            final cat = e.categoria;
            final nombre = cat.nombre;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(MapeadorIconos.obtenerIcono(cat.icono), size: 16, color: Color(int.parse(cat.colorHex))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(nombre, style: TextStyle(fontWeight: FontWeight.bold, color: context.colores.textoPrimario))),
                      Text(e.total.formatear(), style: const TextStyle(color: TemaApp.rojo, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.total.centavos / maxGastoTop,
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
