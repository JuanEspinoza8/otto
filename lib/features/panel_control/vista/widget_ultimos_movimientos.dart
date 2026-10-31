import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tema/tema_app.dart';
import '../../movimientos/logica/movimientos_provider.dart';
import '../../movimientos/vista/fila_movimiento.dart';
import '../../movimientos/vista/pantalla_todos_movimientos.dart';

/// Widget que muestra los últimos movimientos del mes en el dashboard.
class WidgetUltimosMovimientos extends ConsumerWidget {
  const WidgetUltimosMovimientos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movimientos = ref.watch(movimientosControladorProvider).valueOrNull ?? const [];
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
          ...ultimosMovimientos.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: FilaMovimiento(movimiento: m),
              )),
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
