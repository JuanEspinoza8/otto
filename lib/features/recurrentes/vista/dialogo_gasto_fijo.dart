import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../logica/gastos_fijos_provider.dart';
import '../modelo/gasto_fijo.dart';
import '../../../core/dinero/dinero.dart';
import '../../../core/dinero/formateador_monto.dart';

/// Diálogo para crear o editar un gasto fijo.
class DialogoGastoFijo extends ConsumerStatefulWidget {
  final GastoFijo? aEditar;
  const DialogoGastoFijo({super.key, this.aEditar});

  static Future<void> mostrar(BuildContext context, {GastoFijo? aEditar}) {
    return showDialog(
      context: context,
      builder: (_) => DialogoGastoFijo(aEditar: aEditar),
    );
  }

  @override
  ConsumerState<DialogoGastoFijo> createState() => _DialogoGastoFijoState();
}

class _DialogoGastoFijoState extends ConsumerState<DialogoGastoFijo> {
  late final TextEditingController _nombre;
  late final TextEditingController _monto;
  int? _categoriaId;
  int _diaDebito = 1;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.aEditar?.nombre ?? '');
    _monto = TextEditingController(
      text: Dinero.desdeUnidades(widget.aEditar?.monto ?? 0).textoEditable,
    );
    _categoriaId = widget.aEditar?.categoriaId;
    _diaDebito = widget.aEditar?.diaDebito ?? 1;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _monto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    final monto = (Dinero.parsear(_monto.text)?.unidades ?? 0);
    if (nombre.isEmpty || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá nombre y monto válido')),
      );
      return;
    }

    final controlador = ref.read(gastosFijosControladorProvider.notifier);
    if (widget.aEditar == null) {
      await controlador.agregar(GastoFijo(nombre: nombre, monto: monto, categoriaId: _categoriaId, diaDebito: _diaDebito));
    } else {
      await controlador.actualizar(widget.aEditar!.copiaCon(
        nombre: nombre,
        monto: monto,
        categoriaId: _categoriaId,
        diaDebito: _diaDebito,
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
        widget.aEditar == null ? 'Nuevo gasto fijo' : 'Editar gasto fijo',
        style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombre,
              style: TextStyle(color: context.colores.textoPrimario),
              decoration: const InputDecoration(hintText: 'Ej: Alquiler, Luz, Internet'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _monto,
              keyboardType: TextInputType.number,
              inputFormatters: [FormateadorMonto()],
              style: TextStyle(color: context.colores.textoPrimario),
              decoration: const InputDecoration(prefixText: '\$ ', hintText: 'Monto mensual'),
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
