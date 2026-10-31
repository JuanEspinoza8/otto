import 'package:flutter/material.dart';

import '../../../../core/tema/tema_app.dart';

/// Qué se registra desde el formulario.
enum TipoFormulario { gasto, ingreso, ahorro }

/// Selector Gasto / Ingreso / Ahorro.
class SelectorTipo extends StatelessWidget {
  const SelectorTipo({super.key, required this.actual, required this.alCambiar});

  final TipoFormulario actual;
  final ValueChanged<TipoFormulario> alCambiar;

  @override
  Widget build(BuildContext context) {
    Widget boton(TipoFormulario tipo, String titulo, Color color) => Expanded(
          child: _BotonTipo(
            titulo: titulo,
            activo: actual == tipo,
            colorActivo: color,
            alPresionar: () => alCambiar(tipo),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          boton(TipoFormulario.gasto, '💸 Gasto', TemaApp.rojo),
          boton(TipoFormulario.ingreso, '💰 Ingreso', TemaApp.verde),
          boton(TipoFormulario.ahorro, '🏦 Ahorro', TemaApp.azul),
        ],
      ),
    );
  }
}

class _BotonTipo extends StatelessWidget {
  const _BotonTipo({
    required this.titulo,
    required this.activo,
    required this.colorActivo,
    required this.alPresionar,
  });

  final String titulo;
  final bool activo;
  final Color colorActivo;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alPresionar,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: activo ? colorActivo : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          titulo,
          style: TextStyle(
            color: activo ? Colors.white : context.colores.textoSecundario,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
