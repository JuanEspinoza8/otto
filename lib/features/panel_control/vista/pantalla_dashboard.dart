import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/tema/tema_app.dart';
import '../../configuracion/logica/tema_provider.dart';
import '../../movimientos/logica/mes_seleccionado_provider.dart';
import 'encabezado_dashboard.dart';
import 'widget_resumen_tarjetas.dart';
import 'widget_top_gastos.dart';
import 'widget_metas.dart';
import 'widget_resumen_disponible.dart';
import '../../otto/vista/widget_chat_otto.dart';
import 'widget_graficos.dart';
import 'widget_ultimos_movimientos.dart';
import '../../recurrentes/vista/widget_pendientes_mes.dart';
import '../../recurrentes/vista/widget_pregunta_horas_extras.dart';
import '../../recurrentes/vista/widget_saldo_mes_anterior.dart';
import '../../recurrentes/vista/pantalla_notificaciones.dart';

/// Pantalla principal del Dashboard.
/// Cada sección se delega a su widget independiente para cumplir
/// con la regla de 200 líneas máximo por archivo de vista.
class PantallaDashboard extends ConsumerStatefulWidget {
  const PantallaDashboard({super.key});

  @override
  ConsumerState<PantallaDashboard> createState() => _PantallaDashboardState();
}

class _PantallaDashboardState extends ConsumerState<PantallaDashboard> {
  /// Selector de mes compacto (va en la barra superior).
  Widget _selectorMes(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: context.colores.superficieAlta, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              final m = ref.read(mesSeleccionadoProvider);
              ref.read(mesSeleccionadoProvider.notifier).cambiarMes(DateTime(m.year, m.month - 1, 1));
            },
            child: Icon(Icons.arrow_left, size: 20, color: context.colores.textoSecundario),
          ),
          Text(
            DateFormat('MMM yyyy', 'es').format(ref.watch(mesSeleccionadoProvider)).toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colores.textoPrimario),
          ),
          GestureDetector(
            onTap: () {
              final m = ref.read(mesSeleccionadoProvider);
              ref.read(mesSeleccionadoProvider.notifier).cambiarMes(DateTime(m.year, m.month + 1, 1));
            },
            child: Icon(Icons.arrow_right, size: 20, color: context.colores.textoSecundario),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colores.fondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leadingWidth: 150,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: TemaApp.verde, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Flexible(child: Text('Otto', overflow: TextOverflow.ellipsis, style: TextStyle(color: TemaApp.verde, fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
        ),
        title: _selectorMes(context),
        centerTitle: true,
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              ref.watch(temaControladorProvider) == ThemeMode.dark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              color: context.colores.textoSecundario,
            ),
            onPressed: () => ref.read(temaControladorProvider.notifier).alternar(),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.notifications_none, color: context.colores.textoSecundario),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PantallaNotificaciones()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BannerRecordatorio(),
            EncabezadoDashboard(),
            SizedBox(height: 24),

            // Pendientes del mes (sueldo, fijos, cuotas a confirmar).
            // Se auto-oculta (SizedBox.shrink) cuando no hay pendientes.
            WidgetPendientesMes(),

            // Pregunta mensual de horas extras (se auto-oculta).
            WidgetPreguntaHorasExtras(),

            // Sobrante del mes anterior (se auto-oculta).
            WidgetSaldoMesAnterior(),

            // Aviso de resumen del mes anterior listo (se auto-oculta).
            WidgetResumenDisponible(),

            // Tarjetas de resumen
            WidgetResumenTarjetas(),
            SizedBox(height: 24),

            // Top 3 gastos
            WidgetTopGastos(),
            SizedBox(height: 24),

            // Metas de ahorro
            WidgetMetas(),
            SizedBox(height: 24),

            // Chat con Otto
            WidgetChatOtto(),
            SizedBox(height: 24),

            // Gráficos
            WidgetGraficos(),
            SizedBox(height: 24),

            // Últimos movimientos
            WidgetUltimosMovimientos(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
