import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/libro/modelo/meta.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../../../core/utilidades/mapeador_iconos.dart';
import '../logica/metas_provider.dart';
import 'dialogo_aportar_meta.dart';
import 'dialogo_nueva_meta.dart';
import 'dialogo_retirar_mover_meta.dart';

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
