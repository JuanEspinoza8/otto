import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/utilidades/formateador_miles.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../logica/cuotas_provider.dart';
import '../modelo/cuota.dart';

/// Diálogo para crear o editar una cuota en pago.
class DialogoCuota extends ConsumerStatefulWidget {
  final Cuota? aEditar;
  const DialogoCuota({super.key, this.aEditar});

  static Future<void> mostrar(BuildContext context, {Cuota? aEditar}) {
    return showDialog(
      context: context,
      builder: (_) => DialogoCuota(aEditar: aEditar),
    );
  }

  @override
  ConsumerState<DialogoCuota> createState() => _DialogoCuotaState();
}

class _DialogoCuotaState extends ConsumerState<DialogoCuota> {
  late final TextEditingController _nombre;
  late final TextEditingController _monto;
  late final TextEditingController _total;
  late final TextEditingController _pagadas;
  int? _categoriaId;
  int _diaDebito = 1;

  @override
  void initState() {
    super.initState();
    final c = widget.aEditar;
    _nombre = TextEditingController(text: c?.nombre ?? '');
    _monto = TextEditingController(text: montoEditable(c?.montoCuota ?? 0));
    _total = TextEditingController(text: c != null ? c.totalCuotas.toString() : '');
    _pagadas = TextEditingController(text: c != null ? c.cuotasPagadas.toString() : '0');
    _categoriaId = c?.categoriaId;
    _diaDebito = c?.diaDebito ?? 1;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _monto.dispose();
    _total.dispose();
    _pagadas.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    final monto = double.tryParse(_monto.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    final total = int.tryParse(_total.text) ?? 0;
    final pagadas = int.tryParse(_pagadas.text) ?? 0;

    if (nombre.isEmpty || monto <= 0 || total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá nombre, monto y total de cuotas')),
      );
      return;
    }

    final controlador = ref.read(cuotasControladorProvider.notifier);
    final pagadasValidas = pagadas.clamp(0, total);
    if (widget.aEditar == null) {
      await controlador.agregar(Cuota(
        nombre: nombre,
        montoCuota: monto,
        categoriaId: _categoriaId,
        totalCuotas: total,
        cuotasPagadas: pagadasValidas,
        diaDebito: _diaDebito,
        activo: pagadasValidas < total,
      ));
    } else {
      await controlador.actualizar(widget.aEditar!.copiaCon(
        nombre: nombre,
        montoCuota: monto,
        categoriaId: _categoriaId,
        totalCuotas: total,
        cuotasPagadas: pagadasValidas,
        diaDebito: _diaDebito,
        activo: pagadasValidas < total,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categorias = (ref.watch(categoriasControladorProvider).valueOrNull ?? [])
        .where((c) => c.tipo == 'gasto')
        .toList();

    return AlertDialog(
      title: Text(
        widget.aEditar == null ? 'Nueva cuota' : 'Editar cuota',
        style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombre,
              style: TextStyle(color: context.colores.textoPrimario),
              decoration: const InputDecoration(hintText: 'Ej: Heladera, Celular'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _monto,
              keyboardType: TextInputType.number,
              inputFormatters: [FormateadorMiles()],
              style: TextStyle(color: context.colores.textoPrimario),
              decoration: const InputDecoration(prefixText: '\$ ', hintText: 'Monto de cada cuota'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _total,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(color: context.colores.textoPrimario),
                    decoration: const InputDecoration(labelText: 'Total cuotas'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _pagadas,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(color: context.colores.textoPrimario),
                    decoration: const InputDecoration(labelText: 'Ya pagadas'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _categoriaId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Categoría (opcional)'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Otros Gastos')),
                ...categorias.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.nombre))),
              ],
              onChanged: (v) => setState(() => _categoriaId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _diaDebito,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Día de débito del mes'),
              items: [for (int d = 1; d <= 28; d++) DropdownMenuItem(value: d, child: Text('Día $d'))],
              onChanged: (v) => setState(() => _diaDebito = v ?? 1),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: context.colores.textoSecundario)),
        ),
        ElevatedButton(
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(backgroundColor: TemaApp.verde, foregroundColor: Colors.white),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
