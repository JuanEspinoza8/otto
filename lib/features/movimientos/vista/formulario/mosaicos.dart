import 'package:flutter/material.dart';

import '../../../../core/libro/modelo/meta.dart';
import '../../../../core/tema/tema_app.dart';
import '../../../../core/utilidades/mapeador_iconos.dart';
import '../../../categorias/modelo/categoria.dart';

/// Un mosaico de la grilla del formulario (categoría, meta o acción).
class Mosaico extends StatelessWidget {
  const Mosaico({
    super.key,
    required this.icono,
    required this.texto,
    required this.color,
    required this.alTocar,
    this.seleccionado = false,
    this.destacado = false,
    this.subtitulo,
  });

  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback alTocar;
  final bool seleccionado;

  /// Mosaicos de acción ("Nueva", "Cuotas"): fondo tenue y borde de color.
  final bool destacado;
  final String? subtitulo;

  static double ancho(BuildContext context) => (MediaQuery.of(context).size.width - 32 - 36) / 4;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alTocar,
      child: Container(
        width: ancho(context),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: seleccionado || destacado ? color.withValues(alpha: destacado ? 0.08 : 0.15) : context.colores.superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado || destacado ? color : context.colores.borde,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icono, color: color),
            const SizedBox(height: 8),
            Text(
              texto,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: seleccionado || destacado ? FontWeight.bold : FontWeight.normal,
                color: seleccionado || destacado ? color : context.colores.textoPrimario,
              ),
            ),
            if (subtitulo != null)
              Text(subtitulo!, style: TextStyle(fontSize: 9, color: context.colores.textoSecundario)),
          ],
        ),
      ),
    );
  }
}

/// Grilla de categorías del tipo elegido, más "Cuotas" (en gastos) y "Nueva".
class GrillaCategorias extends StatelessWidget {
  const GrillaCategorias({
    super.key,
    required this.categorias,
    required this.seleccionada,
    required this.alElegir,
    required this.alCrear,
    this.alPagarCuotas,
  });

  final List<Categoria> categorias;
  final Categoria? seleccionada;
  final ValueChanged<Categoria> alElegir;
  final VoidCallback alCrear;
  final VoidCallback? alPagarCuotas;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final cat in categorias)
          Mosaico(
            icono: MapeadorIconos.obtenerIcono(cat.icono),
            texto: cat.nombre,
            color: Color(int.parse(cat.colorHex)),
            seleccionado: seleccionada?.id == cat.id,
            alTocar: () => alElegir(cat),
          ),
        if (alPagarCuotas != null)
          Mosaico(icono: Icons.credit_card, texto: 'Cuotas', color: TemaApp.azul, destacado: true, alTocar: alPagarCuotas!),
        Mosaico(icono: Icons.add, texto: 'Nueva', color: TemaApp.verde, destacado: true, alTocar: alCrear),
      ],
    );
  }
}

/// Selector de la meta a la que se aporta.
class SelectorMetas extends StatelessWidget {
  const SelectorMetas({
    super.key,
    required this.metas,
    required this.seleccionada,
    required this.alElegir,
    required this.alCrear,
  });

  final List<Meta> metas;
  final Meta? seleccionada;
  final ValueChanged<Meta> alElegir;
  final VoidCallback alCrear;

  @override
  Widget build(BuildContext context) {
    if (metas.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colores.superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colores.borde),
        ),
        child: Column(
          children: [
            Text('Todavía no tenés metas de ahorro', style: TextStyle(color: context.colores.textoSecundario)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: alCrear,
              icon: const Icon(Icons.add, color: TemaApp.verde),
              label: const Text('Crear meta', style: TextStyle(color: TemaApp.verde, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final meta in metas)
          Mosaico(
            icono: MapeadorIconos.obtenerIcono(meta.icono),
            texto: meta.nombre,
            subtitulo: '${meta.porcentajeProgreso}%',
            color: TemaApp.azul,
            seleccionado: seleccionada?.id == meta.id,
            alTocar: () => alElegir(meta),
          ),
        Mosaico(icono: Icons.add, texto: 'Meta', color: TemaApp.verde, destacado: true, alTocar: alCrear),
      ],
    );
  }
}
