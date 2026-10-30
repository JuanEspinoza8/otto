import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/utilidades/formateador_miles.dart';
import '../../panel_control/vista/pantalla_resumen_mes.dart';
import '../logica/ajustes_provider.dart';
import '../logica/servicio_notificaciones.dart';
import '../logica/servicio_respaldo.dart';
import '../../panel_control/vista/widget_ahorros_acumulados.dart';
import '../../categorias/vista/pantalla_categorias.dart';

class PantallaConfiguracion extends ConsumerStatefulWidget {
  const PantallaConfiguracion({super.key});

  @override
  ConsumerState<PantallaConfiguracion> createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends ConsumerState<PantallaConfiguracion> {
  Future<void> _agregarHorario(BuildContext context, WidgetRef ref) async {
    final TimeOfDay? seleccionado = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );

    if (seleccionado != null) {
      final String horaStr = '${seleccionado.hour.toString().padLeft(2, '0')}:${seleccionado.minute.toString().padLeft(2, '0')}';
      ref.read(ajustesControladorProvider.notifier).agregarHorarioRecordatorio(horaStr);
    }
  }

  Future<void> _editarTexto(BuildContext context, WidgetRef ref, String titulo, String valorActual, void Function(String) alGuardar) async {
    final controlador = TextEditingController(text: valorActual);
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar $titulo'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          keyboardType: (titulo.contains('Salario') || titulo.contains('hora')) ? TextInputType.number : TextInputType.text,
          inputFormatters: (titulo.contains('Salario') || titulo.contains('hora')) ? [FormateadorMiles()] : null,
          decoration: InputDecoration(hintText: titulo),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, controlador.text), child: const Text('Guardar')),
        ],
      ),
    );
    if (resultado != null && resultado.trim().isNotEmpty) {
      alGuardar(resultado.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ajustesAsync = ref.watch(ajustesControladorProvider);
    final ajustes = ajustesAsync.valueOrNull ?? {
      'biometriaActiva': false,
      'recordatorioDiario': true,
      'horariosRecordatorios': ['20:00'],
    };

    final biometriaActiva = ajustes['biometriaActiva'] as bool;
    final recordatorioDiario = ajustes['recordatorioDiario'] as bool;
    final horarios = List<String>.from(ajustes['horariosRecordatorios'] ?? []);
    final nombreUsuario = ajustes['nombreUsuario'] as String? ?? '';
    final salarioMensual = ajustes['salarioMensual'] as double? ?? 0.0;
    final valorHoraExtra = ajustes['valorHoraExtra'] as double? ?? 0.0;

    return Scaffold(
      backgroundColor: context.colores.fondo,
      appBar: AppBar(
        backgroundColor: context.colores.fondo,
        elevation: 0,
        title: Text('Configuración', style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('PERFIL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colores.textoSecundario, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: context.colores.superficie, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.colores.borde)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline, color: Colors.blueGrey),
                  title: const Text('Nombre'),
                  subtitle: Text(nombreUsuario.isEmpty ? 'Sin configurar' : nombreUsuario, style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.edit, size: 16, color: Colors.grey),
                  onTap: () => _editarTexto(context, ref, 'Nombre', nombreUsuario, (valor) {
                    ref.read(ajustesControladorProvider.notifier).actualizarNombre(valor);
                  }),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.attach_money, color: Colors.blueGrey),
                  title: const Text('Salario mensual'),
                  subtitle: Text(
                    salarioMensual > 0 ? '\$${NumberFormat('#,##0.##', 'es_AR').format(salarioMensual)}' : 'Sin configurar',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.edit, size: 16, color: Colors.grey),
                  onTap: () => _editarTexto(context, ref, 'Salario mensual', montoEditable(salarioMensual), (valor) {
                    final salario = double.tryParse(valor.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
                    ref.read(ajustesControladorProvider.notifier).actualizarSalario(salario);
                  }),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.more_time, color: Colors.blueGrey),
                  title: const Text('Valor de hora extra'),
                  subtitle: Text(
                    valorHoraExtra > 0 ? '\$${NumberFormat('#,##0.##', 'es_AR').format(valorHoraExtra)} por hora' : 'Sin configurar',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.edit, size: 16, color: Colors.grey),
                  onTap: () => _editarTexto(context, ref, 'Valor de hora extra', montoEditable(valorHoraExtra), (valor) {
                    final v = double.tryParse(valor.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
                    ref.read(ajustesControladorProvider.notifier).actualizarValorHoraExtra(v);
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const WidgetAhorrosAcumulados(),
          const SizedBox(height: 24),
          Text('SEGURIDAD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colores.textoSecundario, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: context.colores.superficie, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.colores.borde)),
            child: SwitchListTile(
              title: const Text('Bloqueo por Huella Dactilar'),
              subtitle: const Text('Pedir autenticación al abrir la aplicación', style: TextStyle(fontSize: 12)),
              secondary: const Icon(Icons.fingerprint, color: Colors.blueGrey),
              value: biometriaActiva,
              activeThumbColor: TemaApp.verde,
              onChanged: (valor) {
                ref.read(ajustesControladorProvider.notifier).alternarBiometria(valor);
              },
            ),
          ),
          
          const SizedBox(height: 24),
          Text('RECORDATORIOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colores.textoSecundario, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: context.colores.superficie, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.colores.borde)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Recordatorio Diario'),
                  subtitle: const Text('Notificarte para cargar tus gastos', style: TextStyle(fontSize: 12)),
                  secondary: const Icon(Icons.notifications_active, color: Colors.blueGrey),
                  value: recordatorioDiario,
                  activeThumbColor: TemaApp.verde,
                  onChanged: (valor) {
                    ref.read(ajustesControladorProvider.notifier).alternarRecordatorioDiario(valor);
                  },
                ),
                if (recordatorioDiario) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Horarios configurados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        TextButton.icon(
                          onPressed: () => _agregarHorario(context, ref),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Agregar'),
                        ),
                      ],
                    ),
                  ),
                  ...horarios.map((hora) => ListTile(
                    leading: const Icon(Icons.access_time, size: 20),
                    title: Text(hora),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        ref.read(ajustesControladorProvider.notifier).eliminarHorarioRecordatorio(hora);
                      },
                    ),
                  )),
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
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.battery_saver, color: Colors.blueGrey),
                  title: const Text('Permitir notificaciones en segundo plano'),
                  subtitle: const Text('Eximir a Otto de la optimización de batería', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                  onTap: () => ServicioNotificaciones.pedirIgnorarOptimizacionBateria(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text('CATEGORÍAS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colores.textoSecundario, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: context.colores.superficie, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.colores.borde)),
            child: ListTile(
              leading: const Icon(Icons.category_outlined, color: Colors.blueGrey),
              title: const Text('Categorías y presupuestos'),
              subtitle: const Text('Administrá tus rubros y asigná límites de gasto', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaCategorias())),
            ),
          ),
          const SizedBox(height: 24),
          Text('RESUMEN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colores.textoSecundario, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: context.colores.superficie, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.colores.borde)),
            child: ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.blueGrey),
              title: const Text('Ver resumen del mes'),
              subtitle: const Text('Ingresos, gastos y devolución de Otto', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              onTap: () => PantallaResumenMes.mostrar(context, DateTime.now()),
            ),
          ),

          const SizedBox(height: 24),
          Text('DATOS Y RESPALDOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colores.textoSecundario, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: context.colores.superficie, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.colores.borde)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file, color: Colors.blue),
                  title: const Text('Exportar Base de Datos'),
                  subtitle: const Text('Guardar un archivo JSON con tus datos', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    final exito = await ServicioRespaldo.exportarAJSON();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(exito ? 'Exportación exitosa' : 'Error al exportar')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download, color: Colors.orange),
                  title: const Text('Importar Base de Datos'),
                  subtitle: const Text('Cargar datos desde un archivo JSON (¡Reemplazará lo actual!)', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    // Mostrar advertencia primero
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('¿Estás seguro?'),
                        content: const Text('Importar un respaldo reemplazará todos los movimientos y categorías actuales. Esta acción no se puede deshacer.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Importar', style: TextStyle(color: Colors.red))),
                        ],
                      )
                    );
                    
                    if (confirmar == true && context.mounted) {
                      final exito = await ServicioRespaldo.importarDeJSON(ref);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(exito ? 'Datos restaurados correctamente' : 'Error al importar datos')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          Center(child: Text('Otto v1.0', style: TextStyle(color: context.colores.textoSecundario, fontSize: 12))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
