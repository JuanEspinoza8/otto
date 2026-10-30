import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tema/tema_app.dart';
import '../logica/dolar_blue_provider.dart';
import '../../../core/dinero/dinero.dart';

/// Badge compacto que muestra la cotización venta del dólar blue en tiempo real.
class WidgetDolarBlue extends ConsumerWidget {
  const WidgetDolarBlue({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dolarAsync = ref.watch(dolarBlueProvider);

    return dolarAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: TemaApp.verde.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const SizedBox(
          width: 40,
          height: 24,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: TemaApp.verde)),
        ),
      ),
      error: (_, __) => const _Badge(texto: '—'),
      data: (datos) {
        if (datos == null) return const _Badge(texto: '—');
        final venta = datos['venta'] ?? 0;
        return _Badge(texto: Dinero.desdeUnidades(venta).formatear());
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String texto;
  const _Badge({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TemaApp.verde.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monetization_on, size: 12, color: TemaApp.verde),
              SizedBox(width: 4),
              Text('BLUE', style: TextStyle(color: TemaApp.verde, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(texto, style: const TextStyle(color: TemaApp.verde, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
