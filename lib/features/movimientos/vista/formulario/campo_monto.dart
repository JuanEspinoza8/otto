import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/dinero/dinero.dart';
import '../../../../core/dinero/formateador_monto.dart';
import '../../../../core/tema/tema_app.dart';

/// Recuadro grande del monto. En modo horas extra el número son horas y
/// debajo se muestra el total con el valor de la hora configurado.
class CampoMonto extends StatelessWidget {
  const CampoMonto({
    super.key,
    required this.controlador,
    required this.alCambiar,
    this.modoHoras = false,
    this.valorHora = const Dinero.cero(),
  });

  final TextEditingController controlador;
  final VoidCallback alCambiar;
  final bool modoHoras;
  final Dinero valorHora;

  @override
  Widget build(BuildContext context) {
    final horas = (parsearCentesimos(controlador.text) ?? 0) / 100;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colores.borde),
      ),
      child: Column(
        children: [
          Text(
            modoHoras ? 'CANTIDAD DE HORAS' : 'MONTO',
            style: TextStyle(color: context.colores.textoSecundario, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!modoHoras)
                Text(r'$', style: TextStyle(color: context.colores.textoPrimario, fontSize: 48, fontWeight: FontWeight.bold)),
              IntrinsicWidth(
                child: TextField(
                  controller: controlador,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: modoHoras
                      ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}'))]
                      : [FormateadorMonto()],
                  onChanged: (_) => alCambiar(),
                  style: TextStyle(color: context.colores.textoPrimario, fontSize: 56, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: context.colores.textoSecundario),
                    filled: false,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (modoHoras)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('hs', style: TextStyle(color: context.colores.textoSecundario, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          if (modoHoras) ...[
            const SizedBox(height: 8),
            Text(
              valorHora.esPositivo
                  ? '= ${valorHora.por(horas).formatear()}  (a ${valorHora.formatear()}/h)'
                  : 'Configurá el valor de la hora extra en Menú',
              style: const TextStyle(color: TemaApp.verde, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}
