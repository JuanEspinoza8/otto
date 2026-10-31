import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../logica/ajustes_provider.dart';
import '../logica/servicio_notificaciones.dart';

/// Recordatorio diario para cargar gastos, con sus horarios.
class SeccionRecordatorios extends ConsumerWidget {
  const SeccionRecordatorios({super.key});

  Future<void> _agregarHorario(BuildContext context, WidgetRef ref) async {
    final elegido = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
    if (elegido == null) return;
    final hora = '${elegido.hour.toString().padLeft(2, '0')}:${elegido.minute.toString().padLeft(2, '0')}';
    await ref.read(ajustesControladorProvider.notifier).agregarHorarioRecordatorio(hora);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ajustes = ref.watch(ajustesControladorProvider).valueOrNull;
    final activo = ajustes?.recordatorioDiario ?? false;
    final horarios = ajustes?.horariosRecordatorios ?? const <String>[];
    final notifier = ref.read(ajustesControladorProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colores.borde),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Recordatorio diario'),
            subtitle: const Text('Una notificación para cargar tus gastos', style: TextStyle(fontSize: 12)),
            secondary: const Icon(Icons.notifications_active, color: Colors.blueGrey),
            value: activo,
            activeThumbColor: TemaApp.verde,
            onChanged: (valor) => ejecutarConAviso(context, () => notifier.alternarRecordatorioDiario(valor)),
          ),
          if (activo) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Horarios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  TextButton.icon(
                    onPressed: () => _agregarHorario(context, ref),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
            ),
            for (final hora in horarios)
              ListTile(
                leading: const Icon(Icons.access_time, size: 20),
                title: Text(hora),
                trailing: IconButton(
                  tooltip: 'Quitar',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => notifier.eliminarHorarioRecordatorio(hora),
                ),
              ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications_none, color: Colors.blueGrey),
            title: const Text('Probar notificación'),
            subtitle: const Text('Enviar una notificación de prueba ahora', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.send, size: 16, color: Colors.grey),
            onTap: () async {
              await ServicioNotificaciones.mostrarPrueba();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enviada. Si no la ves, revisá los permisos de notificaciones.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
