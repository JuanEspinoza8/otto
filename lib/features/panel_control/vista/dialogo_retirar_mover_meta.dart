import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/dinero/formateador_monto.dart';
import '../../../core/libro/modelo/meta.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../logica/dolar_blue_provider.dart';
import '../logica/metas_provider.dart';

/// Diálogo para retirar plata de una meta: vuelve al disponible como un
/// retiro (el historial de aportes no se toca).
class DialogoRetirarMeta extends ConsumerStatefulWidget {
  final Meta meta;
  const DialogoRetirarMeta({super.key, required this.meta});

  static Future<void> mostrar(BuildContext context, Meta meta) =>
      showDialog(context: context, builder: (_) => DialogoRetirarMeta(meta: meta));

  @override
  ConsumerState<DialogoRetirarMeta> createState() => _DialogoRetirarMetaState();
}

class _DialogoRetirarMetaState extends ConsumerState<DialogoRetirarMeta> {
  final _monto = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _retirar() async {
    final monto = Dinero.parsear(_monto.text, moneda: widget.meta.moneda);
    if (monto == null || !monto.esPositivo) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresá cuánto querés retirar')));
      return;
    }
    setState(() => _guardando = true);
    final ok = await ejecutarConAviso(context, () => ref.read(metasControladorProvider.notifier).retirar(widget.meta, monto));
    if (!mounted) return;
    ok ? Navigator.pop(context) : setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.meta;
    final blue = ref.watch(dolarBlueProvider).valueOrNull?.venta;
    final escrito = Dinero.parsear(_monto.text, moneda: meta.moneda);
    return AlertDialog(
      title: Text('Retirar de ${meta.nombre}', style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tenés guardado ${meta.saldo.formatear()}. Lo que retires vuelve a tu disponible.',
              style: TextStyle(color: context.colores.textoSecundario, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: _monto,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FormateadorMonto()],
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: context.colores.textoPrimario),
            decoration: InputDecoration(prefixText: '${meta.moneda.simbolo} ', hintText: 'Monto a retirar'),
          ),
          if (meta.esUsd) ...[
            const SizedBox(height: 6),
            Text(
              blue != null && blue > 0
                  ? 'Recibís ≈ ${(escrito ?? const Dinero.cero(Moneda.usd)).convertir(Moneda.ars, blue).formatear()} al blue de hoy'
                  : 'Esperando la cotización del dólar…',
              style: const TextStyle(color: TemaApp.azul, fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          ActionChip(
            label: Text('Retirar todo (${meta.saldo.formatear()})'),
            onPressed: () => setState(() => _monto.text = meta.saldo.formatear(simbolo: false)),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: context.colores.textoSecundario))),
        ElevatedButton(
          onPressed: _guardando ? null : _retirar,
          style: ElevatedButton.styleFrom(backgroundColor: TemaApp.rojo, foregroundColor: Colors.white),
          child: const Text('Retirar'),
        ),
      ],
    );
  }
}

/// Diálogo para mover plata de una meta a otra (una sola transferencia,
/// validada contra el saldo de la meta de origen).
class DialogoMoverMeta extends ConsumerStatefulWidget {
  final Meta origen;
  const DialogoMoverMeta({super.key, required this.origen});

  static Future<void> mostrar(BuildContext context, Meta origen) =>
      showDialog(context: context, builder: (_) => DialogoMoverMeta(origen: origen));

  @override
  ConsumerState<DialogoMoverMeta> createState() => _DialogoMoverMetaState();
}

class _DialogoMoverMetaState extends ConsumerState<DialogoMoverMeta> {
  int? _destinoId;
  final _monto = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _mover(Meta destino) async {
    final monto = Dinero.parsear(_monto.text, moneda: widget.origen.moneda);
    if (monto == null || !monto.esPositivo) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresá cuánto mover')));
      return;
    }
    setState(() => _guardando = true);
    final ok = await ejecutarConAviso(
      context,
      () => ref.read(metasControladorProvider.notifier).mover(widget.origen, destino, monto),
    );
    if (!mounted) return;
    ok ? Navigator.pop(context) : setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    final origen = widget.origen;
    final otras = (ref.watch(metasControladorProvider).valueOrNull ?? const <Meta>[]).where((m) => m.id != origen.id).toList();
    final destino = otras.where((m) => m.id == _destinoId).firstOrNull ?? otras.firstOrNull;
    final blue = ref.watch(dolarBlueProvider).valueOrNull?.venta;
    final escrito = Dinero.parsear(_monto.text, moneda: origen.moneda);
    final convierte = destino != null && destino.moneda != origen.moneda;

    return AlertDialog(
      title: Text('Mover de ${origen.nombre}', style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Disponible para mover: ${origen.saldo.formatear()}',
              style: TextStyle(color: context.colores.textoSecundario, fontSize: 13)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: destino?.id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Mover a'),
            items: [
              for (final m in otras)
                DropdownMenuItem<int>(value: m.id, child: Text(m.nombre, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _destinoId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _monto,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FormateadorMonto()],
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: context.colores.textoPrimario),
            decoration: InputDecoration(prefixText: '${origen.moneda.simbolo} ', hintText: 'Monto a mover'),
          ),
          if (convierte) ...[
            const SizedBox(height: 6),
            Text(
              blue != null && blue > 0
                  ? 'Llega ≈ ${(escrito ?? Dinero.cero(origen.moneda)).convertir(destino.moneda, blue).formatear()} al blue de hoy'
                  : 'Esperando la cotización del dólar…',
              style: const TextStyle(color: TemaApp.azul, fontSize: 11),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: context.colores.textoSecundario))),
        ElevatedButton(
          onPressed: (_guardando || destino == null) ? null : () => _mover(destino),
          style: ElevatedButton.styleFrom(backgroundColor: TemaApp.azul, foregroundColor: Colors.white),
          child: const Text('Mover'),
        ),
      ],
    );
  }
}
