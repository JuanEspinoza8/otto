import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/utilidades/mapeador_iconos.dart';
import '../../movimientos/logica/mes_seleccionado_provider.dart';
import '../../../core/libro/consultas_libro.dart';
import '../../../core/libro/libro_providers.dart';
import '../logica/dashboard_provider.dart';
import '../logica/servicio_resumen_mes.dart';
import '../../../core/dinero/dinero.dart';

/// Pantalla de estadísticas detalladas del mes seleccionado. Se abre al tocar
/// cualquiera de los gráficos del dashboard.
class PantallaEstadisticas extends ConsumerWidget {
  const PantallaEstadisticas({super.key});

  static Future<void> mostrar(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PantallaEstadisticas()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mes = ref.watch(mesSeleccionadoProvider);
    final totales = ref.watch(totalesMesProvider).valueOrNull ?? const TotalesMes();
    final disponible = ref.watch(disponibleProvider).valueOrNull ?? const Dinero.cero();
    final resumenAsync = ref.watch(resumenDelMesProvider);

    final mesRaw = DateFormat('MMMM yyyy', 'es').format(mes);
    final mesTxt = mesRaw.isEmpty ? mesRaw : '${mesRaw[0].toUpperCase()}${mesRaw.substring(1)}';

    return Scaffold(
      backgroundColor: context.colores.fondo,
      appBar: AppBar(
        title: Text('Estadísticas · $mesTxt', style: TextStyle(color: context.colores.textoPrimario, fontSize: 18)),
        backgroundColor: context.colores.fondo,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colores.textoPrimario),
      ),
      body: resumenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo armar el resumen', style: TextStyle(color: context.colores.textoSecundario))),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Tarjetas resumen
              _grillaResumen(context, totales, disponible),
              const SizedBox(height: 24),

              if (data.egresos.isNotEmpty) ...[
                _tituloSeccion(context, 'Gastos por categoría', TemaApp.rojo),
                const SizedBox(height: 12),
                _tortaConLeyenda(context, data.egresos, data.totalEgresos),
                const SizedBox(height: 24),
              ],

              if (data.ingresos.isNotEmpty) ...[
                _tituloSeccion(context, 'Ingresos por categoría', TemaApp.verde),
                const SizedBox(height: 12),
                ...data.ingresos.map((l) => _filaCategoria(context, l, data.totalIngresos, TemaApp.verde)),
                const SizedBox(height: 24),
              ],

              if (data.vacio)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('No hay movimientos este mes.',
                        style: TextStyle(color: context.colores.textoSecundario)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _grillaResumen(BuildContext context, TotalesMes totales, Dinero disponible) {
    final ingresos = totales.ingresos;
    final gastos = totales.gastos;
    final aportado = totales.aportadoAMetas;
    final tasaAhorro = totales.porcentajeAhorro;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _tarjeta(context, 'INGRESOS', ingresos, TemaApp.verde)),
            const SizedBox(width: 12),
            Expanded(child: _tarjeta(context, 'GASTOS', gastos, TemaApp.rojo)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _tarjeta(context, 'DISPONIBLE', disponible, TemaApp.azul)),
            const SizedBox(width: 12),
            Expanded(child: _tarjeta(context, 'GUARDADO EN METAS', aportado, TemaApp.azul)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colores.superficie,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colores.borde),
          ),
          child: Row(
            children: [
              const Icon(Icons.savings_outlined, color: TemaApp.verde, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Tasa de ahorro del mes (lo que no gastaste)',
                    style: TextStyle(color: context.colores.textoSecundario, fontSize: 12)),
              ),
              Text('${tasaAhorro.clamp(0, 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: TemaApp.verde, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tarjeta(BuildContext context, String titulo, Dinero monto, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: TextStyle(color: context.colores.textoSecundario, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(monto.formatear(),
                maxLines: 1, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _tituloSeccion(BuildContext context, String texto, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(texto.toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colores.textoSecundario, letterSpacing: 1.1)),
      ],
    );
  }

  Widget _tortaConLeyenda(BuildContext context, List<LineaResumen> lineas, Dinero total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colores.borde),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: lineas.map((l) {
                  final pct = total.esPositivo ? (l.monto.centavos / total.centavos * 100) : 0;
                  return PieChartSectionData(
                    color: Color(int.parse(l.colorHex)),
                    value: l.monto.unidades,
                    title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    radius: 45,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Leyenda COMPLETA (todas las categorías, no solo 3).
          ...lineas.map((l) => _filaCategoria(context, l, total, Color(int.parse(l.colorHex)))),
        ],
      ),
    );
  }

  Widget _filaCategoria(BuildContext context, LineaResumen l, Dinero total, Color color) {
    final pct = total.esPositivo ? (l.monto.centavos / total.centavos * 100) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(MapeadorIconos.obtenerIcono(l.icono), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(l.nombre, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colores.textoPrimario)),
                    ),
                    const SizedBox(width: 8),
                    Text(l.monto.formatear(),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.colores.textoPrimario)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: context.colores.superficieAlta,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${pct.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11, color: context.colores.textoSecundario)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
