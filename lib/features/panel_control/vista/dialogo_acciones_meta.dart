import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/dinero/formateador_monto.dart';
import '../../../core/libro/modelo/meta.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../../../core/utilidades/mapeador_iconos.dart';
import '../logica/dolar_blue_provider.dart';
import '../logica/metas_provider.dart';
import 'dialogo_aportar_meta.dart';
import 'dialogo_nueva_meta.dart';

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
    final otrasMetas = (ref.watch(metasControladorProvider).valueOrNull ?? const <Meta>[]).where((m) => m.id != meta.id);
    final tienePlata = meta.saldo.esPositivo;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(MapeadorIconos.obtenerIcono(meta.icono), color: TemaApp.azul),
            title: Text(meta.nombre, style: TextStyle(fontWeight: FontWeight.bold, color: context.colores.textoPrimario)),
            subtitle: Text(
              '${meta.saldo.formatear()} de ${meta.objetivo.formatear()} · ${meta.porcentajeProgreso.toInt()}%',
              style: TextStyle(color: context.colores.textoSecundario),
            ),
          ),
          Divider(color: context.colores.borde, height: 1),
          _accion(context, Icons.add_circle_outline, 'Aportar plata', TemaApp.verde, () {
            Navigator.pop(context);
            DialogoAportarMeta.mostrar(context, meta);
          }),
          _accion(context, Icons.remove_circle_outline, 'Retirar plata', TemaApp.rojo, tienePlata
              ? () {
                  Navigator.pop(context);
                  DialogoRetirarMeta.mostrar(context, meta);
                }
              : null),
          _accion(context, Icons.swap_horiz, 'Mover a otra meta', TemaApp.azul, (tienePlata && otrasMetas.isNotEmpty)
              ? () {
                  Navigator.pop(context);
                  DialogoMoverMeta.mostrar(context, meta);
                }
              : null),
          _accion(context, Icons.edit_outlined, 'Editar meta', context.colores.textoPrimario, () {
            Navigator.pop(context);
            DialogoNuevaMeta.mostrar(context, aEditar: meta);
          }),
          _accion(context, Icons.delete_outline, 'Eliminar meta', TemaApp.rojo, () => _eliminar(context, ref)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _eliminar(BuildContext context, WidgetRef ref) async {
    final navegador = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar meta', style: TextStyle(color: ctx.colores.textoPrimario)),
        content: Text(
          meta.saldo.esPositivo
              ? '¿Eliminar "${meta.nombre}"? Sus ${meta.saldo.formatear()} vuelven a tu disponible como un retiro; el historial no se borra.'
              : '¿Eliminar "${meta.nombre}"?',
          style: TextStyle(color: ctx.colores.textoSecundario),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: ctx.colores.textoSecundario))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: TemaApp.rojo, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final hecho = await ejecutarConAviso(context, () => ref.read(metasControladorProvider.notifier).eliminar(meta));
    if (hecho) navegador.pop();
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
