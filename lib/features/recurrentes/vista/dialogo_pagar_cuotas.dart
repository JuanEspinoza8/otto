import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/dinero/dinero.dart';
import '../../../core/ui/acciones.dart';
import '../logica/planes_provider.dart';
import '../modelo/plan.dart';

/// Diálogo para cancelar/pagar N cuotas de una deuda.
class DialogoPagarCuotas extends ConsumerStatefulWidget {
  final Plan? inicial;
  const DialogoPagarCuotas({super.key, this.inicial});

  static Future<void> mostrar(BuildContext context, {Plan? inicial}) {
    return showDialog(context: context, builder: (_) => DialogoPagarCuotas(inicial: inicial));
  }

  @override
  ConsumerState<DialogoPagarCuotas> createState() => _DialogoPagarCuotasState();
}

class _DialogoPagarCuotasState extends ConsumerState<DialogoPagarCuotas> {
  Plan? _sel;
  bool _guardando = false;
  final _cantidad = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _sel = widget.inicial;
  }

  @override
  void dispose() {
    _cantidad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activas = ref.watch(cuotasProvider).where((c) => c.activo && !c.terminado).toList();

    if (activas.isEmpty) {
      return AlertDialog(
        title: Text('Pagar cuotas', style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
        content: Text('No tenés cuotas en curso.', style: TextStyle(color: context.colores.textoSecundario)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      );
    }

    // Aseguramos que la selección exista en la lista.
    _sel ??= activas.first;
    if (!activas.any((c) => c.id == _sel!.id)) _sel = activas.first;

    final n = int.tryParse(_cantidad.text) ?? 0;
    final cap = n.clamp(0, _sel!.cuotasRestantes);
    var total = const Dinero.cero();
    for (var k = _sel!.cuotasPagadas + 1; k <= _sel!.cuotasPagadas + cap; k++) {
      total += _sel!.montoDeCuota(k);
    }

    return AlertDialog(
      title: Text('Pagar cuotas', style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _sel!.id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '¿Qué cuota?'),
            items: activas
                .map((c) => DropdownMenuItem<int>(
                      value: c.id,
                      child: Text('${c.nombre} (${c.cuotasPagadas}/${c.totalCuotas})', overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _sel = activas.firstWhere((c) => c.id == v)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cantidad,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: context.colores.textoPrimario),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: '¿Cuántas cuotas pagás?', helperText: 'Restan ${_sel!.cuotasRestantes}'),
          ),
          const SizedBox(height: 12),
          Text('Total a pagar: ${total.formatear()}',
              style: const TextStyle(color: TemaApp.rojo, fontWeight: FontWeight.bold)),
          if (cap > 0)
            Text('Quedarían ${_sel!.cuotasPagadas + cap}/${_sel!.totalCuotas} pagadas',
                style: TextStyle(color: context.colores.textoSecundario, fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: context.colores.textoSecundario))),
        ElevatedButton(
          onPressed: cap <= 0 || _guardando
              ? null
              : () async {
                  final plan = _sel!;
                  setState(() => _guardando = true);
                  final ok = await ejecutarConAviso(
                    context,
                    () => ref.read(planesControladorProvider.notifier).adelantarCuotas(plan, cap),
                    exito: '✅ Pagaste $cap ${cap == 1 ? 'cuota' : 'cuotas'} de "${plan.nombre}"',
                  );
                  if (!context.mounted) return;
                  ok ? Navigator.pop(context) : setState(() => _guardando = false);
                },
          style: ElevatedButton.styleFrom(backgroundColor: TemaApp.verde, foregroundColor: Colors.white),
          child: const Text('Pagar'),
        ),
      ],
    );
  }
}
