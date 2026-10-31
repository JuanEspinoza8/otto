import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/dinero/formateador_monto.dart';
import '../../../core/libro/modelo/movimiento.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../logica/movimientos_provider.dart';

/// Diálogo para editar un movimiento existente (monto, concepto, categoría
/// y fecha). El tipo (ingreso/gasto) se mantiene fijo.
class DialogoEditarMovimiento extends ConsumerStatefulWidget {
  final Movimiento movimiento;
  const DialogoEditarMovimiento({super.key, required this.movimiento});

  static Future<void> mostrar(BuildContext context, Movimiento m) {
    return showDialog(
      context: context,
      builder: (_) => DialogoEditarMovimiento(movimiento: m),
    );
  }

  @override
  ConsumerState<DialogoEditarMovimiento> createState() => _DialogoEditarMovimientoState();
}

class _DialogoEditarMovimientoState extends ConsumerState<DialogoEditarMovimiento> {
  late final TextEditingController _monto;
  late final TextEditingController _concepto;
  late DateTime _fecha;
  late int _categoriaId;

  @override
  void initState() {
    super.initState();
    _monto = TextEditingController(text: widget.movimiento.monto.textoEditable);
    _concepto = TextEditingController(text: widget.movimiento.descripcion ?? '');
    _fecha = widget.movimiento.fecha;
    // Solo se editan ingresos y gastos, que siempre tienen categoría.
    _categoriaId = widget.movimiento.categoriaId ?? 0;
  }

  @override
  void dispose() {
    _monto.dispose();
    _concepto.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final sel = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (sel != null) setState(() => _fecha = sel);
  }

  bool _guardando = false;

  Future<void> _guardar() async {
    final monto = Dinero.parsear(_monto.text);
    if (monto == null || !monto.esPositivo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá un monto válido')),
      );
      return;
    }
    setState(() => _guardando = true);
    final ok = await ejecutarConAviso(
      context,
      () => ref.read(movimientosControladorProvider.notifier).editar(
            widget.movimiento,
            monto: monto,
            categoriaId: _categoriaId,
            fecha: _fecha,
            descripcion: _concepto.text,
          ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipo = widget.movimiento.tipo.valor;
    final categorias = (ref.watch(categoriasControladorProvider).valueOrNull ?? [])
        .where((c) => c.tipo == tipo)
        .toList();
    // Aseguramos que el id actual esté entre las opciones.
    final hayActual = categorias.any((c) => c.id == _categoriaId);

    return AlertDialog(
      title: Text(
        tipo == 'ingreso' ? 'Editar ingreso' : 'Editar gasto',
        style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _monto,
              keyboardType: TextInputType.number,
              inputFormatters: [FormateadorMonto()],
              style: TextStyle(color: context.colores.textoPrimario),
              decoration: const InputDecoration(prefixText: '\$ ', hintText: 'Monto'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _concepto,
              style: TextStyle(color: context.colores.textoPrimario),
              decoration: const InputDecoration(hintText: 'Concepto (opcional)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: hayActual ? _categoriaId : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: categorias
                  .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.nombre)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _categoriaId = v);
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _elegirFecha,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.colores.superficieAlta,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: context.colores.textoSecundario),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat("d 'de' MMMM, yyyy", 'es').format(_fecha),
                      style: TextStyle(color: context.colores.textoPrimario),
                    ),
                  ],
                ),
              ),
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
