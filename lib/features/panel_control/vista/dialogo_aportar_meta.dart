import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/utilidades/formateador_miles.dart';
import '../logica/ahorro_disponible_provider.dart';
import '../logica/ahorros_provider.dart';
import '../logica/dashboard_provider.dart';
import '../logica/dolar_blue_provider.dart';
import '../logica/metas_provider.dart';
import '../modelo/meta.dart';

/// Diálogo para aportar dinero a una meta de ahorro (o eliminarla).
class DialogoAportarMeta extends ConsumerStatefulWidget {
  final Meta meta;
  const DialogoAportarMeta({super.key, required this.meta});

  static Future<void> mostrar(BuildContext context, Meta meta) {
    return showDialog(context: context, builder: (_) => DialogoAportarMeta(meta: meta));
  }

  @override
  ConsumerState<DialogoAportarMeta> createState() => _DialogoAportarMetaState();
}

class _DialogoAportarMetaState extends ConsumerState<DialogoAportarMeta> {
  final _monto = TextEditingController();
  final _formato = NumberFormat('#,##0.##', 'es_AR');

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _aportar() async {
    // Siempre se ingresa en PESOS (es lo que tiene el usuario).
    final pesos = double.tryParse(_monto.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    if (pesos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá un monto a aportar')),
      );
      return;
    }
    // Sólo validamos el tope si el disponible ya cargó del todo (si no, sería
    // parcial y daría un número equivocado).
    final datosListos = ref.read(ahorrosControladorProvider).hasValue && ref.read(totalesGlobalesProvider).hasValue;
    final disponible = ref.read(ahorroDisponibleProvider);
    if (datosListos && pesos > disponible + 0.5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No te alcanza. Disponible: \$${_formato.format(disponible)}')),
      );
      return;
    }

    final blue = ref.read(dolarBlueProvider).valueOrNull?['venta'] ?? 0.0;
    if (widget.meta.esUsd && blue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperá a que cargue la cotización del dólar')),
      );
      return;
    }

    await ref.read(metasControladorProvider.notifier).aportar(widget.meta, pesos, blue: blue);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.meta;
    final disponible = ref.watch(ahorroDisponibleProvider);
    final blue = ref.watch(dolarBlueProvider).valueOrNull?['venta'] ?? 0.0;
    final simbolo = meta.esUsd ? 'U\$D' : '\$';

    // Lo que falta de la meta, expresado en PESOS (para los botones rápidos).
    final restanteMeta = (meta.montoObjetivo - meta.montoActual).clamp(0.0, double.infinity);
    final restanteEnPesos = meta.esUsd ? restanteMeta * blue : restanteMeta;
    final aFalta = restanteEnPesos < disponible ? restanteEnPesos : disponible;

    // Conversión en vivo de lo escrito (si es meta USD).
    final pesosEscritos = double.tryParse(_monto.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    final usdEquivalente = (meta.esUsd && blue > 0) ? pesosEscritos / blue : 0;

    return AlertDialog(
      title: Text(meta.nombre, style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ahorrado: $simbolo${_formato.format(meta.montoActual)} de $simbolo${_formato.format(meta.montoObjetivo)}',
            style: TextStyle(color: context.colores.textoSecundario, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: meta.porcentajeProgreso / 100,
              minHeight: 8,
              backgroundColor: context.colores.superficieAlta,
              valueColor: const AlwaysStoppedAnimation<Color>(TemaApp.verde),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 16, color: disponible > 0 ? TemaApp.verde : TemaApp.rojo),
              const SizedBox(width: 6),
              Text(
                'Disponible: \$${_formato.format(disponible)}',
                style: TextStyle(color: disponible > 0 ? TemaApp.verde : TemaApp.rojo, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _monto,
            keyboardType: TextInputType.number,
            inputFormatters: [FormateadorMiles()],
            style: TextStyle(color: context.colores.textoPrimario),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixText: '\$ ',
              hintText: meta.esUsd ? 'Pesos a aportar' : 'Monto a aportar',
            ),
          ),
          if (meta.esUsd) ...[
            const SizedBox(height: 6),
            Text(
              blue > 0
                  ? 'Se convierte a ≈ U\$D ${usdEquivalente.toStringAsFixed(2)} (blue \$${_formato.format(blue)})'
                  : 'Esperando cotización del dólar…',
              style: const TextStyle(color: TemaApp.azul, fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          if (disponible <= 0)
            Text('No tenés plata disponible para asignar. Cargá ingresos o ahorros previos.',
                style: TextStyle(color: context.colores.textoSecundario, fontSize: 11))
          else
            Wrap(
              spacing: 8,
              children: [
                if (aFalta > 0)
                  ActionChip(
                    label: Text('Lo que falta (\$${_formato.format(aFalta)})'),
                    onPressed: () => setState(() => _monto.text = montoEditable(aFalta)),
                  ),
                ActionChip(
                  label: Text('Todo lo disponible (\$${_formato.format(disponible)})'),
                  onPressed: () => setState(() => _monto.text = montoEditable(disponible)),
                ),
              ],
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: context.colores.textoSecundario)),
        ),
        ElevatedButton(
          onPressed: _aportar,
          style: ElevatedButton.styleFrom(backgroundColor: TemaApp.verde, foregroundColor: Colors.white),
          child: const Text('Aportar'),
        ),
      ],
    );
  }
}
