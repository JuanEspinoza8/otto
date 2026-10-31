import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/utilidades/texto.dart';
import '../../configuracion/logica/tema_provider.dart';
import '../../configuracion/logica/ajustes_provider.dart';
import '../../movimientos/logica/mes_seleccionado_provider.dart';
import 'widget_resumen_tarjetas.dart';
import 'widget_top_gastos.dart';
import 'widget_metas.dart';
import 'widget_resumen_disponible.dart';
import '../../otto/vista/widget_chat_otto.dart';
import 'widget_dolar_blue.dart';
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
  static const _claveBannerOculto = 'recordatorioBannerOculto';
  bool _mostrarRecordatorio = false;
  String _nombreUsuario = '';

  @override
  void initState() {
    super.initState();
    _cargarEstadoInicial();
  }

  Future<void> _cargarEstadoInicial() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nombreUsuario = prefs.getString('nombreUsuario') ?? '';
      // Mostramos el banner sólo si el usuario no lo descartó antes.
      _mostrarRecordatorio = !(prefs.getBool(_claveBannerOculto) ?? false);
    });
  }

  /// Persiste el descarte del banner para que no reaparezca.
  Future<void> _ocultarBanner() async {
    // Ocultamos de inmediato (UI) y luego persistimos.
    if (mounted) setState(() => _mostrarRecordatorio = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_claveBannerOculto, true);
    } catch (_) {/* si falla la persistencia, igual queda oculto en esta sesión */}
  }

  /// Activa el recordatorio diario y descarta el banner.
  Future<void> _activarRecordatorios() async {
    // Ocultar el banner SIEMPRE, aunque falle programar las notificaciones.
    await _ocultarBanner();
    try {
      await ref.read(ajustesControladorProvider.notifier).alternarRecordatorioDiario(true);
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔔 Recordatorios diarios activados a las 20:00')),
      );
    }
  }

  String _obtenerSaludo() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Recordatorio
            if (_mostrarRecordatorio) ...[
              _BannerRecordatorio(
                alActivar: _activarRecordatorios,
                alCerrar: _ocultarBanner,
              ),
              const SizedBox(height: 24),
            ],

            // Encabezado + Dólar Blue
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_obtenerSaludo()}, ${_nombreUsuario.isNotEmpty ? capitalizar(_nombreUsuario) : 'Usuario'} 👋',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.colores.textoPrimario),
                      ),
                      const SizedBox(height: 4),
                      Text('¡Vas muy bien! Tu esfuerzo se está notando.', style: TextStyle(color: context.colores.textoSecundario, fontSize: 12)),
                    ],
                  ),
                ),
                const WidgetDolarBlue(),
              ],
            ),
            const SizedBox(height: 24),

            // Pendientes del mes (sueldo, fijos, cuotas a confirmar).
            // Se auto-oculta (SizedBox.shrink) cuando no hay pendientes.
            const WidgetPendientesMes(),

            // Pregunta mensual de horas extras (se auto-oculta).
            const WidgetPreguntaHorasExtras(),

            // Sobrante del mes anterior (se auto-oculta).
            const WidgetSaldoMesAnterior(),

            // Aviso de resumen del mes anterior listo (se auto-oculta).
            const WidgetResumenDisponible(),

            // Tarjetas de resumen
            const WidgetResumenTarjetas(),
            const SizedBox(height: 24),

            // Top 3 gastos
            const WidgetTopGastos(),
            const SizedBox(height: 24),

            // Metas de ahorro
            const WidgetMetas(),
            const SizedBox(height: 24),

            // Chat con Otto
            const WidgetChatOtto(),
            const SizedBox(height: 24),

            // Gráficos
            const WidgetGraficos(),
            const SizedBox(height: 24),

            // Últimos movimientos
            const WidgetUltimosMovimientos(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Banner de recordatorio de notificaciones.
class _BannerRecordatorio extends StatelessWidget {
  final VoidCallback alActivar;
  final VoidCallback alCerrar;
  const _BannerRecordatorio({required this.alActivar, required this.alCerrar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colores.superficie,
        border: Border.all(color: TemaApp.verde.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: TemaApp.verde.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤔', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(child: Text('¿Querés que te recuerde cargar tus gastos?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.colores.textoPrimario))),
            ],
          ),
          const SizedBox(height: 8),
          Text('Otto te manda un recordatorio cada noche para que no pierdas el control de tu plata.', style: TextStyle(fontSize: 12, color: context.colores.textoSecundario)),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: alActivar,
                style: ElevatedButton.styleFrom(backgroundColor: TemaApp.verde, foregroundColor: Colors.white, elevation: 0),
                child: const Text('Activar recordatorios', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: alCerrar,
                child: Text('Ahora no', style: TextStyle(color: context.colores.textoSecundario)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
