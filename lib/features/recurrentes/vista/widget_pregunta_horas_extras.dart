import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../logica/horas_extras_provider.dart';
import '../../../core/dinero/dinero.dart';

/// Cartel del dashboard que pregunta una vez por mes si hizo horas extras.
class WidgetPreguntaHorasExtras extends ConsumerWidget {
  const WidgetPreguntaHorasExtras({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mostrar = ref.watch(horasExtrasMesProvider).valueOrNull ?? false;
    if (!mostrar) return const SizedBox.shrink();

    final notifier = ref.read(horasExtrasMesProvider.notifier);

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
              const Icon(Icons.more_time, color: TemaApp.verde, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('¿Hiciste horas extras este mes?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.colores.textoPrimario)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _DialogoHorasExtras.mostrar(context),
                style: ElevatedButton.styleFrom(backgroundColor: TemaApp.verde, foregroundColor: Colors.white, elevation: 0),
                child: const Text('Sí, cargar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => notifier.descartar(),
                child: Text('No', style: TextStyle(color: context.colores.textoSecundario)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialogoHorasExtras extends ConsumerStatefulWidget {
  const _DialogoHorasExtras();

  static Future<void> mostrar(BuildContext context) {
    return showDialog(context: context, builder: (_) => const _DialogoHorasExtras());
  }

  @override
  ConsumerState<_DialogoHorasExtras> createState() => _DialogoHorasExtrasState();
}

class _DialogoHorasExtrasState extends ConsumerState<_DialogoHorasExtras> {
  final _horas = TextEditingController();

  @override
  void dispose() {
    _horas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valor = ref.read(horasExtrasMesProvider.notifier).valorHora;
    final horas = (parsearCentesimos(_horas.text) ?? 0) / 100;
    final total = horas * valor;

    return AlertDialog(
      title: Text('Horas extras', style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _horas,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*'))],
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: context.colores.textoPrimario),
            decoration: const InputDecoration(hintText: 'Cantidad de horas', suffixText: 'hs'),
          ),
          const SizedBox(height: 12),
          Text(
            'A ${Dinero.desdeUnidades(valor).formatear()}/h = ${Dinero.desdeUnidades(total).formatear()}',
            style: const TextStyle(color: TemaApp.verde, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: context.colores.textoSecundario)),
        ),
        ElevatedButton(
          onPressed: () async {
            if (horas <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresá las horas')));
              return;
            }
            await ref.read(horasExtrasMesProvider.notifier).registrarHoras(horas);
            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: TemaApp.verde, foregroundColor: Colors.white),
          child: const Text('Cargar'),
        ),
      ],
    );
  }
}
