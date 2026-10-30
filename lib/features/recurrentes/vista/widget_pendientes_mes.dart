import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/tema/tema_app.dart';
import '../logica/pendientes_provider.dart';

/// Tarjeta del dashboard que lista los movimientos recurrentes pendientes de
/// confirmar para el mes seleccionado (sueldo, gastos fijos y cuotas).
class WidgetPendientesMes extends ConsumerWidget {
  const WidgetPendientesMes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendientesAsync = ref.watch(pendientesMesProvider);
    final pendientes = pendientesAsync.valueOrNull ?? [];

    if (pendientes.isEmpty) return const SizedBox.shrink();

    final formato = NumberFormat('#,##0.##', 'es_AR');
    final notifier = ref.read(pendientesMesProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
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
              const Text('🗓️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('PENDIENTES DEL MES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colores.textoSecundario, letterSpacing: 1.1)),
              ),
              TextButton(
                onPressed: () => notifier.confirmarTodos(),
                child: const Text('Confirmar todo', style: TextStyle(color: TemaApp.verde, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...pendientes.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      p.esIngreso ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 16,
                      color: p.esIngreso ? TemaApp.verde : TemaApp.rojo,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p.nombre, style: TextStyle(color: context.colores.textoPrimario, fontSize: 13)),
                    ),
                    Text(
                      '${p.esIngreso ? '+' : '-'}\$${formato.format(p.monto)}',
                      style: TextStyle(
                        color: p.esIngreso ? TemaApp.verde : TemaApp.rojo,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => notifier.confirmar(p),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: TemaApp.verde.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Confirmar', style: TextStyle(color: TemaApp.verde, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
