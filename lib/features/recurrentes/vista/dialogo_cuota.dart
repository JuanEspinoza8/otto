import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../logica/planes_provider.dart';
import '../modelo/plan.dart';
import '../../../core/ui/acciones.dart';
import '../../../core/utilidades/fechas.dart';
import '../../../core/dinero/dinero.dart';
import '../../../core/dinero/formateador_monto.dart';

/// Diálogo para crear o editar una cuota en pago.
class DialogoCuota extends ConsumerStatefulWidget {
  final Plan? aEditar;
  const DialogoCuota({super.key, this.aEditar});

  static Future<void> mostrar(BuildContext context, {Plan? aEditar}) {
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
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final c = widget.aEditar;
    _nombre = TextEditingController(text: c?.nombre ?? '');
    _monto = TextEditingController(text: c?.monto.textoEditable ?? '');
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
    final monto = Dinero.parsear(_monto.text);
    final total = int.tryParse(_total.text) ?? 0;
    final pagadas = int.tryParse(_pagadas.text) ?? 0;

    if (nombre.isEmpty || monto == null || !monto.esPositivo || total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá nombre, monto y total de cuotas')),
      );
      return;
    }

    final previo = widget.aEditar;
    final plan = Plan(
      id: previo?.id,
      tipo: TipoPlan.cuotas,
      nombre: nombre,
      categoriaId: _categoriaId,
      monto: monto,
      total: monto.por(total),
      totalCuotas: total,
      primerPeriodo: previo?.primerPeriodo ?? Periodo.de(DateTime.now()),
      diaDebito: _diaDebito,
      activo: previo?.activo ?? true,
    );
    final controlador = ref.read(planesControladorProvider.notifier);
    setState(() => _guardando = true);
    final ok = await ejecutarConAviso(
      context,
      () => previo == null ? controlador.crearCuotas(plan, yaPagadas: pagadas) : controlador.actualizar(plan),
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
              inputFormatters: [FormateadorMonto()],
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
                  // Al editar, las pagadas salen de los meses confirmados: se
                  // cambian pagando cuotas o borrando el gasto generado.
                  child: TextField(
                    controller: _pagadas,
                    enabled: widget.aEditar == null,
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
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(backgroundColor: TemaApp.verde, foregroundColor: Colors.white),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
