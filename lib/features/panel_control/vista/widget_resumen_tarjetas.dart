import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/libro/consultas_libro.dart';
import '../../../core/libro/libro_providers.dart';
import '../../../core/tema/tema_app.dart';
import '../logica/dashboard_provider.dart';
import '../logica/dolar_blue_provider.dart';
import '../logica/metas_provider.dart';
import 'tarjetas_resumen.dart';

/// Tarjetas superiores del dashboard. Al tocar un monto se cicla el formato
/// (K / M / exacto).
class WidgetResumenTarjetas extends ConsumerStatefulWidget {
  const WidgetResumenTarjetas({super.key});

  @override
  ConsumerState<WidgetResumenTarjetas> createState() => _WidgetResumenTarjetasState();
}

class _WidgetResumenTarjetasState extends ConsumerState<WidgetResumenTarjetas> {
  int _formato = 0;

  void _ciclarFormato() => setState(() => _formato = (_formato + 1) % 3);

  @override
  Widget build(BuildContext context) {
    final totales = ref.watch(totalesMesProvider).valueOrNull ?? const TotalesMes();
    final progreso = ref.watch(progresoMetasProvider);
    final disponible = ref.watch(disponibleProvider).valueOrNull ?? const Dinero.cero();
    final dolares = ref.watch(patrimonioDolaresProvider).valueOrNull;
    final blue = ref.watch(dolarBlueProvider).valueOrNull?.venta;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TarjetaResumen(
                titulo: 'INGRESOS',
                monto: totales.ingresos,
                formato: _formato,
                onTapMonto: _ciclarFormato,
                subMontoText: '${totales.cantidadIngresos} movimientos',
                colorBg: TemaApp.verde,
                colorText: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TarjetaResumen(
                titulo: 'GASTOS',
                monto: totales.gastos,
                formato: _formato,
                onTapMonto: _ciclarFormato,
                subMontoText: '${totales.cantidadGastos} movimientos',
                colorBg: TemaApp.rojo,
                colorText: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TarjetaResumen(
                titulo: 'DISPONIBLE',
                monto: disponible,
                formato: _formato,
                onTapMonto: _ciclarFormato,
                subtitulo: 'Pesos libres para gastar o ahorrar',
                colorBg: context.colores.superficie,
              ),
            ),
            const SizedBox(width: 12),
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
                    Text(
                      'META TOTAL',
                      style: TextStyle(color: context.colores.textoSecundario, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      progreso.cantidad > 0 ? '${progreso.porcentaje.floor()}%' : '—',
                      style: TextStyle(color: context.colores.textoPrimario, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      progreso.cantidad > 0 ? 'en ${progreso.cantidad} metas' : 'Sin metas activas',
                      style: TextStyle(color: context.colores.textoSecundario, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (dolares != null && dolares.total.esPositivo) ...[
          const SizedBox(height: 12),
          TarjetaDolares(dolares: dolares, blue: blue),
        ],
      ],
    );
  }
}
