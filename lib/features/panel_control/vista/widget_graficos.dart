import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/libro/consultas_libro.dart';
import '../logica/dashboard_provider.dart';
import 'pantalla_estadisticas.dart';

/// Widget que muestra los gráficos de dona y barras del dashboard.
class WidgetGraficos extends ConsumerWidget {
  const WidgetGraficos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranking = ref.watch(rankingGastosProvider).valueOrNull ?? const <TotalCategoria>[];
    final totales = ref.watch(totalesMesProvider).valueOrNull ?? const TotalesMes();
    final top3 = ranking.take(3).toList();
    final ingresos = totales.ingresos.unidades;
    final gastos = totales.gastos.unidades;
    final ahorro = totales.resultado.esPositivo ? totales.resultado.unidades : 0.0;
    final maximo = [ingresos, gastos, 1.0].reduce((a, b) => a > b ? a : b);

    return GestureDetector(
      onTap: () => PantallaEstadisticas.mostrar(context),
      behavior: HitTestBehavior.opaque,
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gráfico de Dona - Por Categoría
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colores.superficie,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colores.borde),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: TemaApp.verde, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('POR CATEGORÍA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: context.colores.textoSecundario, letterSpacing: 1.1)),
                  ],
                ),
                const SizedBox(height: 16),
                if (ranking.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 25,
                        sections: [
                          for (final e in ranking)
                            PieChartSectionData(
                              color: Color(int.parse(e.categoria.colorHex)),
                              value: e.total.unidades,
                              title: '',
                              radius: 15,
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(height: 120, child: Center(child: Text('Sin gastos', style: TextStyle(color: context.colores.textoSecundario)))),
                const SizedBox(height: 16),
                ...top3.map((e) {
                  final nombre = e.categoria.nombre;
                  final colorHex = e.categoria.colorHex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: Color(int.parse(colorHex)), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(nombre, style: TextStyle(fontSize: 10, color: context.colores.textoPrimario), overflow: TextOverflow.ellipsis)),
                        Text(e.total.formatear(abreviado: true), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.colores.textoPrimario)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Gráfico de Barras - Ingresos vs Gastos
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colores.superficie,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colores.borde),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: TemaApp.verde, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('ING. VS GASTOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: context.colores.textoSecundario, letterSpacing: 1.1)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maximo * 1.2,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: ingresos, color: TemaApp.verde, width: 20, borderRadius: BorderRadius.circular(2))]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: gastos, color: TemaApp.rojo, width: 20, borderRadius: BorderRadius.circular(2))]),
                        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: ahorro, color: TemaApp.azul, width: 20, borderRadius: BorderRadius.circular(2))]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Ing.', style: TextStyle(fontSize: 10, color: context.colores.textoSecundario)),
                    Text('Gas.', style: TextStyle(fontSize: 10, color: context.colores.textoSecundario)),
                    Text('Bal.', style: TextStyle(fontSize: 10, color: context.colores.textoSecundario)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }
}
