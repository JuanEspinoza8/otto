import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../../panel_control/logica/metas_provider.dart';
import '../logica/saldo_mes_anterior_provider.dart';
import '../../../core/dinero/dinero.dart';

/// Tarjeta que ofrece qué hacer con el sobrante del mes anterior.
class WidgetSaldoMesAnterior extends ConsumerWidget {
  const WidgetSaldoMesAnterior({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sobra = ref.watch(saldoMesAnteriorProvider).valueOrNull ?? const Dinero.cero();
    if (!sobra.esPositivo) return const SizedBox.shrink();

    final notifier = ref.read(saldoMesAnteriorProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.verde.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💸', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Te sobraron ${sobra.formatear()} del mes pasado',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.colores.textoPrimario)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('¿Lo guardás en una meta? Si no, queda en tu disponible.', style: TextStyle(color: context.colores.textoSecundario, fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _elegirMeta(context, ref, sobra),
                style: ElevatedButton.styleFrom(backgroundColor: TemaApp.verde, foregroundColor: Colors.white, elevation: 0),
                child: const Text('Aportar a una meta', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => notifier.descartar(),
                child: Text('Dejarlo disponible', style: TextStyle(color: context.colores.textoSecundario)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _elegirMeta(BuildContext context, WidgetRef ref, Dinero sobra) {
    final metas = ref.read(metasControladorProvider).valueOrNull ?? const [];
    if (metas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tenés metas creadas todavía')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿A qué meta lo aportás?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ctx.colores.textoPrimario)),
            const SizedBox(height: 12),
            ...metas.map((m) => ListTile(
                  title: Text(m.nombre, style: TextStyle(color: ctx.colores.textoPrimario)),
                  trailing: Text(m.esUsd ? 'USD' : 'ARS', style: TextStyle(color: ctx.colores.textoSecundario, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    // El aporte se valida contra el objetivo de la meta: si no
                    // entra todo, se avisa y el sobrante sigue disponible.
                    ejecutarConAviso(
                      context,
                      () => ref.read(saldoMesAnteriorProvider.notifier).aportarAMeta(m, sobra.min(m.esUsd ? sobra : m.falta)),
                      exito: 'Guardado en "${m.nombre}"',
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }
}
