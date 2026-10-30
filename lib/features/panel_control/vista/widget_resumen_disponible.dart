import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/tema/tema_app.dart';
import '../logica/resumen_auto_provider.dart';
import 'pantalla_resumen_mes.dart';

/// Tarjeta del dashboard que avisa que el resumen del mes anterior está listo.
class WidgetResumenDisponible extends ConsumerWidget {
  const WidgetResumenDisponible({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mes = ref.watch(resumenAutoProvider).valueOrNull;
    if (mes == null) return const SizedBox.shrink();

    final mesTxt = capitalizarMes(DateFormat('MMMM', 'es').format(mes));
    final notifier = ref.read(resumenAutoProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.azul.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('El resumen de $mesTxt ya está listo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.colores.textoPrimario)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  PantallaResumenMes.mostrar(context, mes);
                  notifier.marcarVisto();
                },
                style: ElevatedButton.styleFrom(backgroundColor: TemaApp.azul, foregroundColor: Colors.white, elevation: 0),
                child: const Text('Ver resumen', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => notifier.marcarVisto(),
                child: Text('Después', style: TextStyle(color: context.colores.textoSecundario)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
