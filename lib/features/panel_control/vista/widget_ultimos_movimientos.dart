import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tema/tema_app.dart';
import '../../movimientos/logica/movimientos_provider.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../logica/metas_provider.dart';
import '../../../core/ui/widgets/tarjeta_movimiento.dart';
import '../../../core/ui/widgets/categoria_ahorro.dart';
import '../../movimientos/vista/pantalla_todos_movimientos.dart';

/// Widget que muestra los últimos movimientos del mes en el dashboard.
class WidgetUltimosMovimientos extends ConsumerWidget {
  const WidgetUltimosMovimientos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movimientosAsync = ref.watch(movimientosControladorProvider);
    final categoriasAsync = ref.watch(categoriasControladorProvider);
    final metas = (ref.watch(metasControladorProvider).valueOrNull ?? {}).keys;

    final movimientos = movimientosAsync.valueOrNull ?? [];
    final categorias = categoriasAsync.valueOrNull ?? [];
    final ultimosMovimientos = movimientos.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: TemaApp.verde, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('ÚLTIMOS MOVIMIENTOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colores.textoSecundario, letterSpacing: 1.1)),
          ],
        ),
        const SizedBox(height: 12),
        if (ultimosMovimientos.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('No hay movimientos recientes.', style: TextStyle(color: context.colores.textoSecundario)),
            ),
          )
        else
          ...ultimosMovimientos.map((m) {
            final categoria = categoriaDeMovimiento(m, categorias, metas);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TarjetaMovimiento(
                movimiento: m,
                categoria: categoria,
                alEliminar: () {
                  if (m.esAhorro) {
                    ref.read(metasControladorProvider.notifier).revertirAporte(m);
                  } else {
                    ref.read(movimientosControladorProvider.notifier).eliminarMovimiento(m.id!);
                  }
                },
              ),
            );
          }),
        if (ultimosMovimientos.isNotEmpty) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PantallaTodosMovimientos()),
              ),
              icon: const Icon(Icons.list_alt, size: 18, color: TemaApp.verde),
              label: const Text('Ver todos los movimientos del mes',
                  style: TextStyle(color: TemaApp.verde, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: TemaApp.verde),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
