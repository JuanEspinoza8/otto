import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/utilidades/texto.dart';
import '../../categorias/vista/pantalla_categorias.dart';
import '../../panel_control/vista/pantalla_resumen_mes.dart';
import '../../panel_control/vista/widget_ahorros_acumulados.dart';
import 'seccion_perfil.dart';
import 'seccion_recordatorios.dart';
import 'seccion_respaldo.dart';
import 'seccion_seguridad.dart';

/// Menú: perfil, ahorro previo, seguridad, recordatorios, categorías,
/// resúmenes y respaldos. Cada sección es su propio widget.
class PantallaConfiguracion extends StatelessWidget {
  const PantallaConfiguracion({super.key});

  /// Elige uno de los últimos 12 meses para ver su resumen.
  Future<void> _elegirResumen(BuildContext context) async {
    final ahora = DateTime.now();
    final meses = [for (var i = 0; i < 12; i++) DateTime(ahora.year, ahora.month - i)];
    final elegido = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('¿Qué mes querés ver?', style: TextStyle(fontWeight: FontWeight.bold))),
            for (final m in meses)
              ListTile(
                title: Text(capitalizar(DateFormat('MMMM yyyy', 'es').format(m))),
                onTap: () => Navigator.pop(ctx, m),
              ),
          ],
        ),
      ),
    );
    if (elegido != null && context.mounted) await PantallaResumenMes.mostrar(context, elegido);
  }

  @override
  Widget build(BuildContext context) {
    Widget titulo(String texto) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(texto,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colores.textoSecundario, letterSpacing: 1.2)),
        );
    Widget tarjeta(Widget hijo) => Container(
          decoration: BoxDecoration(
            color: context.colores.superficie,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colores.borde),
          ),
          child: hijo,
        );

    return Scaffold(
      backgroundColor: context.colores.fondo,
      appBar: AppBar(
        backgroundColor: context.colores.fondo,
        elevation: 0,
        title: Text('Configuración', style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          titulo('PERFIL'),
          const SeccionPerfil(),
          const SizedBox(height: 24),
          const WidgetAhorrosAcumulados(),
          titulo('PRIVACIDAD Y SEGURIDAD'),
          const SeccionSeguridad(),
          titulo('RECORDATORIOS'),
          const SeccionRecordatorios(),
          titulo('CATEGORÍAS'),
          tarjeta(ListTile(
            leading: const Icon(Icons.category_outlined, color: Colors.blueGrey),
            title: const Text('Categorías y presupuestos'),
            subtitle: const Text('Administrá tus rubros y asigná límites de gasto', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaCategorias())),
          )),
          titulo('RESUMEN'),
          tarjeta(ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.blueGrey),
            title: const Text('Ver el resumen de un mes'),
            subtitle: const Text('Ingresos, gastos y devolución de Otto', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            onTap: () => _elegirResumen(context),
          )),
          titulo('DATOS Y RESPALDOS'),
          const SeccionRespaldo(),
          const SizedBox(height: 40),
          Center(child: Text('Otto', style: TextStyle(color: context.colores.textoSecundario, fontSize: 12))),
        ],
      ),
    );
  }
}
