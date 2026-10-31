import 'package:flutter/material.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/tema/tema_app.dart';
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

/// Dólares del usuario, aparte del disponible: no se mezclan con los pesos
/// para que el disponible no cambie cuando se mueve el blue.
class TarjetaDolares extends StatelessWidget {
  const TarjetaDolares({super.key, required this.dolares, required this.blue});

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

class TarjetaResumen extends StatelessWidget {
  final String titulo;
  final Dinero monto;
  final int formato;
  final VoidCallback onTapMonto;
  final Color colorBg;
  final Color? colorText;
  final String? subtitulo;
  final String? subMontoText;

  const TarjetaResumen({
    super.key,
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
