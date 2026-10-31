import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../logica/ajustes_provider.dart';

/// Bloqueo con huella o PIN y uso de la IA.
class SeccionSeguridad extends ConsumerWidget {
  const SeccionSeguridad({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ajustes = ref.watch(ajustesControladorProvider).valueOrNull;
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
            title: const Text('Bloqueo con huella o PIN'),
            subtitle: const Text(
              'Pide autenticarse al volver a la app y la oculta en recientes y capturas',
              style: TextStyle(fontSize: 12),
            ),
            secondary: const Icon(Icons.fingerprint, color: Colors.blueGrey),
            value: ajustes?.biometriaActiva ?? false,
            activeThumbColor: TemaApp.verde,
            onChanged: (valor) => ejecutarConAviso(context, () => notifier.alternarBiometria(valor)),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Otto con IA'),
            subtitle: const Text(
              'El chat y el resumen del mes mandan el texto, las categorías y los totales a un servicio de IA externo. '
              'Apagado, el chat interpreta los mensajes en el teléfono.',
              style: TextStyle(fontSize: 12),
            ),
            secondary: const Icon(Icons.auto_awesome_outlined, color: Colors.blueGrey),
            value: ajustes?.iaActiva ?? true,
            activeThumbColor: TemaApp.verde,
            onChanged: notifier.alternarIa,
          ),
        ],
      ),
    );
  }
}
