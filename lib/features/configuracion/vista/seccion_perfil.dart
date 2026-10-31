import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/dinero/formateador_monto.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../logica/ajustes_provider.dart';

/// Nombre, sueldo y valor de la hora extra.
class SeccionPerfil extends ConsumerWidget {
  const SeccionPerfil({super.key});

  Future<String?> _pedirTexto(BuildContext context, String titulo, String actual, {bool monto = false}) {
    final controlador = TextEditingController(text: actual);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar $titulo'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          keyboardType: monto ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          inputFormatters: monto ? [FormateadorMonto()] : null,
          decoration: InputDecoration(hintText: monto ? '0 = sin configurar' : titulo, prefixText: monto ? r'$ ' : null),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, controlador.text), child: const Text('Guardar')),
        ],
      ),
    );
  }

  Future<void> _editarMonto(
    BuildContext context,
    String titulo,
    Dinero actual,
    Future<void> Function(Dinero) guardar,
  ) async {
    final texto = await _pedirTexto(context, titulo, actual.textoEditable, monto: true);
    if (texto == null || !context.mounted) return;
    final monto = texto.trim().isEmpty ? const Dinero.cero() : Dinero.parsear(texto);
    if (monto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Monto inválido')));
      return;
    }
    await ejecutarConAviso(context, () => guardar(monto));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ajustes = ref.watch(ajustesControladorProvider).valueOrNull;
    final notifier = ref.read(ajustesControladorProvider.notifier);
    final nombre = ajustes?.nombreUsuario ?? '';
    final salario = ajustes?.salarioMensual ?? const Dinero.cero();
    final valorHora = ajustes?.valorHoraExtra ?? const Dinero.cero();

    return Container(
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colores.borde),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.blueGrey),
            title: const Text('Nombre'),
            subtitle: Text(nombre.isEmpty ? 'Sin configurar' : nombre, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.edit, size: 16, color: Colors.grey),
            onTap: () async {
              final texto = await _pedirTexto(context, 'Nombre', nombre);
              if (texto != null && texto.trim().isNotEmpty) await notifier.actualizarNombre(texto);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.attach_money, color: Colors.blueGrey),
            title: const Text('Sueldo mensual'),
            subtitle: Text(
              salario.esPositivo ? '${salario.formatear()} · se pide confirmar cada mes' : 'Sin configurar',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.edit, size: 16, color: Colors.grey),
            onTap: () => _editarMonto(context, 'sueldo mensual', salario, notifier.actualizarSalario),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.more_time, color: Colors.blueGrey),
            title: const Text('Valor de la hora extra'),
            subtitle: Text(
              valorHora.esPositivo ? '${valorHora.formatear()} por hora' : 'Sin configurar',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.edit, size: 16, color: Colors.grey),
            onTap: () => _editarMonto(context, 'valor de la hora extra', valorHora, notifier.actualizarValorHoraExtra),
          ),
        ],
      ),
    );
  }
}
