import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../logica/respaldo_provider.dart';
import '../logica/servicio_respaldo.dart';

/// Exportar e importar el respaldo en JSON.
class SeccionRespaldo extends ConsumerWidget {
  const SeccionRespaldo({super.key});

  void _avisar(BuildContext context, String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: error ? TemaApp.rojo : null),
    );
  }

  Future<void> _exportar(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(respaldoControladorProvider.notifier).exportar();
    } catch (_) {
      if (context.mounted) _avisar(context, 'No se pudo exportar el respaldo', error: true);
    }
  }

  Future<void> _importar(BuildContext context, WidgetRef ref) async {
    final controlador = ref.read(respaldoControladorProvider.notifier);
    try {
      // Primero se lee y valida el archivo, sin tocar nada.
      final respaldo = await controlador.elegir();
      if (respaldo == null || !context.mounted) return;
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Reemplazar tus datos?'),
          content: Text(
            'El respaldo tiene ${respaldo.movimientos} movimientos, ${respaldo.metas} metas y '
            '${respaldo.planes} fijos, cuotas o sueldo. Hoy tenés ${respaldo.movimientosActuales} movimientos.\n\n'
            'Se reemplaza todo por el respaldo. Antes se guarda una copia de la base actual en el teléfono.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reemplazar', style: TextStyle(color: TemaApp.rojo))),
          ],
        ),
      );
      if (confirmar != true || !context.mounted) return;
      await controlador.restaurar(respaldo);
      if (context.mounted) _avisar(context, 'Datos restaurados correctamente');
    } on ErrorRespaldo catch (e) {
      if (context.mounted) _avisar(context, '${e.mensaje}. No se cambió nada.', error: true);
    } catch (_) {
      if (context.mounted) _avisar(context, 'No se pudo importar el respaldo. No se cambió nada.', error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colores.borde),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.blue),
            title: const Text('Exportar respaldo'),
            subtitle: const Text('Compartir un archivo JSON con todos tus datos', style: TextStyle(fontSize: 12)),
            onTap: () => _exportar(context, ref),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.file_download, color: Colors.orange),
            title: const Text('Importar respaldo'),
            subtitle: const Text('Muestra qué trae el archivo antes de reemplazar los datos', style: TextStyle(fontSize: 12)),
            onTap: () => _importar(context, ref),
          ),
        ],
      ),
    );
  }
}
