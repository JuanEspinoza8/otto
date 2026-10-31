import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/libro/consultas_libro.dart';
import '../../../core/libro/libro_providers.dart';
import '../../../core/tema/tema_app.dart';
import '../logica/dashboard_provider.dart';
import '../logica/dolar_blue_provider.dart';
import '../logica/metas_provider.dart';

/// Formatea un monto según el modo elegido (0: K, 1: M/m, 2: exacto).
String formatearMontoResumen(Dinero monto, int modo) {
  final unidades = monto.unidades.abs();
  final signo = monto.esNegativo ? '-' : '';
  final simbolo = monto.moneda.simbolo;
  switch (modo) {
    case 1:
      if (unidades >= 1000000) return '$signo$simbolo${(unidades / 1000000).toStringAsFixed(2).replaceAll('.', ',')}M';
      if (unidades >= 1000) return '$signo$simbolo${(unidades / 1000).round()}m';
      return monto.formatear();
    case 2:
      return monto.formatear();
    default:
      if (unidades >= 1000) return '$signo$simbolo${(unidades / 1000).round()}K';
      return monto.formatear();
  }
}

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
              child: _TarjetaResumen(
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
              child: _TarjetaResumen(
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
              child: _TarjetaResumen(
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
          _TarjetaDolares(dolares: dolares, blue: blue),
        ],
      ],
    );
  }
}

/// Dólares del usuario, aparte del disponible: no se mezclan con los pesos
/// para que el disponible no cambie cuando se mueve el blue.
class _TarjetaDolares extends StatelessWidget {
  const _TarjetaDolares({required this.dolares, required this.blue});

  final PatrimonioDolares dolares;
  final double? blue;

  @override
  Widget build(BuildContext context) {
    final enPesos = dolares.enPesos(blue);
    final detalle = [
      if (dolares.libres.esPositivo) '${dolares.libres.formatear()} libres',
      if (dolares.enMetas.esPositivo) '${dolares.enMetas.formatear()} en metas',
    ].join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colores.borde),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money, color: TemaApp.azul),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DÓLARES', style: TextStyle(color: context.colores.textoSecundario, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                Text(detalle, style: TextStyle(color: context.colores.textoSecundario, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(dolares.total.formatear(), style: const TextStyle(color: TemaApp.azul, fontSize: 18, fontWeight: FontWeight.bold)),
              if (enPesos != null)
                Text('≈ ${enPesos.formatear(abreviado: true)} al blue',
                    style: TextStyle(color: context.colores.textoSecundario, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  final String titulo;
  final Dinero monto;
  final int formato;
  final VoidCallback onTapMonto;
  final Color colorBg;
  final Color? colorText;
  final String? subtitulo;
  final String? subMontoText;

  const _TarjetaResumen({
    required this.titulo,
    required this.monto,
    required this.formato,
    required this.onTapMonto,
    required this.colorBg,
    this.colorText,
    this.subtitulo,
    this.subMontoText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorBg,
        borderRadius: BorderRadius.circular(16),
        border: colorBg == context.colores.superficie ? Border.all(color: context.colores.borde) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: colorText != null ? colorText!.withValues(alpha: 0.8) : context.colores.textoSecundario,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTapMonto,
            behavior: HitTestBehavior.opaque,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatearMontoResumen(monto, formato),
                maxLines: 1,
                style: TextStyle(
                  color: colorText ?? (monto.esNegativo ? TemaApp.rojo : TemaApp.verde),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitulo!,
              style: TextStyle(
                color: colorText != null ? colorText!.withValues(alpha: 0.8) : context.colores.textoSecundario,
                fontSize: 10,
              ),
            ),
          ],
          if (subMontoText != null) ...[
            const SizedBox(height: 4),
            Text(
              subMontoText!,
              style: TextStyle(
                color: colorText != null ? colorText!.withValues(alpha: 0.8) : context.colores.textoSecundario,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
