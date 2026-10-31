import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/dinero/formateador_monto.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../../../core/utilidades/fechas.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../logica/planes_provider.dart';
import '../modelo/plan.dart';

/// Diálogo para crear o editar un gasto fijo.
class DialogoGastoFijo extends ConsumerStatefulWidget {
  final Plan? aEditar;
  const DialogoGastoFijo({super.key, this.aEditar});

  static Future<void> mostrar(BuildContext context, {Plan? aEditar}) {
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
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.aEditar?.nombre ?? '');
    _monto = TextEditingController(text: widget.aEditar?.monto.textoEditable ?? '');
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
    final monto = Dinero.parsear(_monto.text);
    if (nombre.isEmpty || monto == null || !monto.esPositivo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá nombre y monto válido')),
      );
      return;
    }

    final previo = widget.aEditar;
    // Un fijo nuevo empieza a pedirse desde este mes (no aparece como
    // pendiente en meses anteriores a su creación).
    final plan = Plan(
      id: previo?.id,
      tipo: TipoPlan.fijo,
      nombre: nombre,
      categoriaId: _categoriaId,
      monto: monto,
      primerPeriodo: previo?.primerPeriodo ?? Periodo.de(DateTime.now()),
      diaDebito: _diaDebito,
      activo: previo?.activo ?? true,
    );
    final controlador = ref.read(planesControladorProvider.notifier);
    setState(() => _guardando = true);
    final ok = await ejecutarConAviso(
      context,
      () => previo == null ? controlador.crear(plan) : controlador.actualizar(plan),
    );
    if (!mounted) return;
    ok ? Navigator.pop(context) : setState(() => _guardando = false);
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
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(backgroundColor: TemaApp.verde, foregroundColor: Colors.white),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
