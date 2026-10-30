import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/utilidades/mapeador_iconos.dart';
import '../logica/dolar_blue_provider.dart';
import '../logica/metas_provider.dart';
import '../modelo/meta.dart';
import 'dialogo_aportar_meta.dart';
import 'dialogo_nueva_meta.dart';
import '../../../core/dinero/dinero.dart';
import '../../../core/dinero/formateador_monto.dart';

/// Menú de acciones de una meta: aportar, retirar, mover, editar y eliminar.
class DialogoAccionesMeta extends ConsumerWidget {
  final Meta meta;
  const DialogoAccionesMeta({super.key, required this.meta});

  static Future<void> mostrar(BuildContext context, Meta meta) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: context.colores.superficie,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DialogoAccionesMeta(meta: meta),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simbolo = meta.esUsd ? 'U\$D' : '\$';
    final otrasMetas = (ref.watch(metasControladorProvider).valueOrNull ?? {}).keys.where((m) => m.id != meta.id).toList();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(MapeadorIconos.obtenerIcono(meta.icono), color: TemaApp.azul),
            title: Text(meta.nombre, style: TextStyle(fontWeight: FontWeight.bold, color: context.colores.textoPrimario)),
            subtitle: Text(
              '$simbolo${Dinero.desdeUnidades(meta.montoActual).formatear(simbolo: false)} de $simbolo${Dinero.desdeUnidades(meta.montoObjetivo).formatear(simbolo: false)} · ${meta.porcentajeProgreso.toInt()}%',
              style: TextStyle(color: context.colores.textoSecundario),
            ),
          ),
          Divider(color: context.colores.borde, height: 1),
          _accion(context, Icons.add_circle_outline, 'Aportar plata', TemaApp.verde, () {
            Navigator.pop(context);
            DialogoAportarMeta.mostrar(context, meta);
          }),
          _accion(context, Icons.remove_circle_outline, 'Retirar plata', TemaApp.rojo,
              meta.montoActual > 0
                  ? () {
                      Navigator.pop(context);
                      DialogoRetirarMeta.mostrar(context, meta);
                    }
                  : null),
          _accion(context, Icons.swap_horiz, 'Mover a otra meta', TemaApp.azul,
              (meta.montoActual > 0 && otrasMetas.isNotEmpty)
                  ? () {
                      Navigator.pop(context);
                      DialogoMoverMeta.mostrar(context, meta);
                    }
                  : null),
          _accion(context, Icons.edit_outlined, 'Editar meta', context.colores.textoPrimario, () {
            Navigator.pop(context);
            DialogoNuevaMeta.mostrar(context, aEditar: meta);
          }),
          _accion(context, Icons.delete_outline, 'Eliminar meta', TemaApp.rojo, () async {
            final navigator = Navigator.of(context);
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Eliminar meta', style: TextStyle(color: ctx.colores.textoPrimario)),
                content: Text('¿Seguro que querés eliminar "${meta.nombre}"? La plata guardada vuelve a tu disponible.',
                    style: TextStyle(color: ctx.colores.textoSecundario)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: ctx.colores.textoSecundario))),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: TemaApp.rojo, fontWeight: FontWeight.bold))),
                ],
              ),
            );
            if (ok == true) {
              await ref.read(metasControladorProvider.notifier).eliminarMeta(meta.id!);
              navigator.pop();
            }
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _accion(BuildContext context, IconData icono, String texto, Color color, VoidCallback? onTap) {
    final habilitado = onTap != null;
    return ListTile(
      enabled: habilitado,
      leading: Icon(icono, color: habilitado ? color : context.colores.textoSecundario),
      title: Text(texto, style: TextStyle(color: habilitado ? context.colores.textoPrimario : context.colores.textoSecundario)),
      onTap: onTap,
    );
  }
}

/// Diálogo para retirar plata de una meta (vuelve al disponible).
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

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _retirar() async {
    final meta = widget.meta;
    final valor = (Dinero.parsear(_monto.text)?.unidades ?? 0);
    if (valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresá cuánto querés retirar')));
      return;
    }
    final retiro = valor.clamp(0.0, meta.montoActual);
    await ref.read(metasControladorProvider.notifier).retirar(meta, retiro);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.meta;
    final simbolo = meta.esUsd ? 'U\$D' : '\$';
    return AlertDialog(
      title: Text('Retirar de ${meta.nombre}', style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tenés guardado $simbolo${Dinero.desdeUnidades(meta.montoActual).formatear(simbolo: false)}. Lo que retires vuelve a tu disponible.',
              style: TextStyle(color: context.colores.textoSecundario, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: _monto,
            keyboardType: TextInputType.number,
            inputFormatters: [FormateadorMonto()],
            style: TextStyle(color: context.colores.textoPrimario),
            decoration: InputDecoration(prefixText: '$simbolo ', hintText: 'Monto a retirar'),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              label: Text('Retirar todo ($simbolo${Dinero.desdeUnidades(meta.montoActual).formatear(simbolo: false)})'),
              onPressed: () => setState(() => _monto.text = Dinero.desdeUnidades(meta.montoActual).textoEditable),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: context.colores.textoSecundario))),
        ElevatedButton(
          onPressed: _retirar,
          style: ElevatedButton.styleFrom(backgroundColor: TemaApp.rojo, foregroundColor: Colors.white),
          child: const Text('Retirar'),
        ),
      ],
    );
  }
}

/// Diálogo para mover plata de una meta a otra.
class DialogoMoverMeta extends ConsumerStatefulWidget {
  final Meta origen;
  const DialogoMoverMeta({super.key, required this.origen});

  static Future<void> mostrar(BuildContext context, Meta origen) =>
      showDialog(context: context, builder: (_) => DialogoMoverMeta(origen: origen));

  @override
  ConsumerState<DialogoMoverMeta> createState() => _DialogoMoverMetaState();
}

class _DialogoMoverMetaState extends ConsumerState<DialogoMoverMeta> {
  Meta? _destino;
  final _monto = TextEditingController();

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _mover() async {
    final origen = widget.origen;
    if (_destino == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Elegí la meta destino')));
      return;
    }
    final pesos = (Dinero.parsear(_monto.text)?.unidades ?? 0);
    if (pesos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresá cuánto mover')));
      return;
    }
    final blue = ref.read(dolarBlueProvider).valueOrNull?['venta'] ?? 0.0;
    if ((origen.esUsd || _destino!.esUsd) && blue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esperá a que cargue la cotización del dólar')));
      return;
    }
    await ref.read(metasControladorProvider.notifier).moverEntreMetas(origen, _destino!, pesos, blue: blue);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final origen = widget.origen;
    final blue = ref.watch(dolarBlueProvider).valueOrNull?['venta'] ?? 0.0;
    final otras = (ref.watch(metasControladorProvider).valueOrNull ?? {}).keys.where((m) => m.id != origen.id).toList();
    // Disponible de la meta origen, en pesos.
    final disponibleOrigenPesos = origen.esUsd ? origen.montoActual * blue : origen.montoActual;

    _destino ??= otras.isNotEmpty ? otras.first : null;
    if (_destino != null && !otras.any((m) => m.id == _destino!.id)) {
      _destino = otras.isNotEmpty ? otras.first : null;
    }

    return AlertDialog(
      title: Text('Mover de ${origen.nombre}', style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Disponible para mover: ${Dinero.desdeUnidades(disponibleOrigenPesos).formatear()}',
              style: TextStyle(color: context.colores.textoSecundario, fontSize: 13)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _destino?.id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Mover a'),
            items: otras.map((m) => DropdownMenuItem<int>(value: m.id, child: Text(m.nombre, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setState(() => _destino = otras.firstWhere((m) => m.id == v)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _monto,
            keyboardType: TextInputType.number,
            inputFormatters: [FormateadorMonto()],
            style: TextStyle(color: context.colores.textoPrimario),
            decoration: const InputDecoration(prefixText: '\$ ', hintText: 'Monto en pesos a mover'),
          ),
          const SizedBox(height: 6),
          Text('Se mueve en pesos. Si al destino no le entra todo, el resto queda en tu disponible.',
              style: TextStyle(color: context.colores.textoSecundario, fontSize: 11)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: context.colores.textoSecundario))),
        ElevatedButton(
          onPressed: _mover,
          style: ElevatedButton.styleFrom(backgroundColor: TemaApp.azul, foregroundColor: Colors.white),
          child: const Text('Mover'),
        ),
      ],
    );
  }
}
