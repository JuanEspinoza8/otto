import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/tema/tema_app.dart';

/// Campos de concepto y fecha del formulario de movimientos.
class ConceptoYFecha extends StatelessWidget {
  const ConceptoYFecha({
    super.key,
    required this.concepto,
    required this.fecha,
    required this.alCambiarFecha,
  });

  final TextEditingController concepto;
  final DateTime fecha;
  final ValueChanged<DateTime> alCambiarFecha;

  Future<void> _elegirFecha(BuildContext context) async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (elegida != null) alCambiarFecha(elegida);
  }

  @override
  Widget build(BuildContext context) {
    final etiqueta = TextStyle(fontSize: 12, color: context.colores.textoSecundario, fontWeight: FontWeight.bold, letterSpacing: 1.1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('CONCEPTO', style: etiqueta),
        const SizedBox(height: 8),
        TextField(
          controller: concepto,
          style: TextStyle(color: context.colores.textoPrimario),
          decoration: InputDecoration(
            hintText: 'Ej: almuerzo en el trabajo',
            hintStyle: TextStyle(color: context.colores.textoSecundario, fontSize: 14),
            filled: true,
            fillColor: context.colores.superficie,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),
        Text('FECHA', style: etiqueta),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _elegirFecha(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(color: context.colores.superficie, borderRadius: BorderRadius.circular(12)),
            child: Text(
              DateFormat("dd 'de' MMMM, yyyy", 'es').format(fecha),
              style: TextStyle(fontSize: 14, color: context.colores.textoPrimario),
            ),
          ),
        ),
      ],
    );
  }
}
