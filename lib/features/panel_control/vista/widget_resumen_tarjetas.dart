import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tema/tema_app.dart';
import '../logica/dashboard_provider.dart';
import '../logica/ahorro_disponible_provider.dart';
import '../logica/metas_provider.dart';
import '../../../core/dinero/dinero.dart';

/// Formatea un monto según el modo elegido (0: K, 1: M/m, 2: exacto).
String formatearMontoResumen(double m, int modo) {
  switch (modo) {
    case 1: // Millones / miles
      if (m >= 1000000) return '${(m / 1000000).toStringAsFixed(2).replaceAll('.', ',')}M';
      if (m >= 1000) return '${(m / 1000).round()}m';
      return Dinero.desdeUnidades(m).formatear(simbolo: false);
    case 2: // Exacto
      return Dinero.desdeUnidades(m).formatear(simbolo: false);
    default: // K
      if (m >= 1000) return '${(m / 1000).round()}K';
      return Dinero.desdeUnidades(m).formatear(simbolo: false);
  }
}

/// Widget que muestra las 4 tarjetas superiores del dashboard.
/// Al tocar cualquiera de los montos grandes se cicla el formato (K / M / exacto).
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
    final resumen = ref.watch(resumenMensualProvider).valueOrNull ?? const <String, double>{};
    final progresoMeta = ref.watch(progresoMetaTotalProvider);
    final disponible = ref.watch(ahorroDisponibleProvider);

    final cantIngresos = resumen['cantidadIngresos']?.toInt() ?? 0;
    final cantGastos = resumen['cantidadGastos']?.toInt() ?? 0;
    final porcentajeMeta = progresoMeta['porcentaje'] ?? 0;
    final montoDineroMeta = progresoMeta['montoObjetivo'] ?? 0;
    final cantMetas = progresoMeta['cantidadMetas']?.toInt() ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TarjetaResumen(
                titulo: 'INGRESOS',
                monto: resumen['ingresos'] ?? 0,
                formato: _formato,
                onTapMonto: _ciclarFormato,
                subMontoText: '$cantIngresos movimientos',
                colorBg: TemaApp.verde,
                colorText: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TarjetaResumen(
                titulo: 'GASTOS',
                monto: resumen['gastos'] ?? 0,
                formato: _formato,
                onTapMonto: _ciclarFormato,
                subMontoText: '$cantGastos movimientos',
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
                subtitulo: 'Plata libre para gastar o ahorrar',
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
                      cantMetas > 0 ? '${porcentajeMeta.floor()}%' : '—',
                      style: TextStyle(color: context.colores.textoPrimario, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      cantMetas > 0
                          ? 'de ${Dinero.desdeUnidades(montoDineroMeta).formatear()} en $cantMetas metas'
                          : 'Sin metas activas',
                      style: TextStyle(color: context.colores.textoSecundario, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  final String titulo;
  final double monto;
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
                '${monto < 0 ? '-' : ''}\$${formatearMontoResumen(monto.abs(), formato)}',
                maxLines: 1,
                style: TextStyle(
                  color: colorText ?? (monto < 0 ? TemaApp.rojo : TemaApp.verde),
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
