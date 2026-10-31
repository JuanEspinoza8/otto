import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/dinero/formateador_monto.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../logica/ahorros_provider.dart';

/// Ahorro previo: la plata que el usuario ya tenía antes de usar la app.
/// Los pesos son el saldo inicial del disponible; los dólares, el de la
/// cuenta "Dólares" (se muestran aparte).
class WidgetAhorrosAcumulados extends ConsumerStatefulWidget {
  const WidgetAhorrosAcumulados({super.key});

  @override
  ConsumerState<WidgetAhorrosAcumulados> createState() => _WidgetAhorrosAcumuladosState();
}

class _WidgetAhorrosAcumuladosState extends ConsumerState<WidgetAhorrosAcumulados> {
  final _ars = TextEditingController();
  final _usd = TextEditingController();
  bool _cargado = false;

  @override
  void dispose() {
    _ars.dispose();
    _usd.dispose();
    super.dispose();
  }

  Future<void> _guardar(Moneda moneda) async {
    final controlador = moneda == Moneda.ars ? _ars : _usd;
    final monto = controlador.text.trim().isEmpty
        ? Dinero.cero(moneda)
        : Dinero.parsear(controlador.text, moneda: moneda);
    if (monto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Monto inválido')));
      return;
    }
    final notifier = ref.read(ahorroPrevioControladorProvider.notifier);
    await ejecutarConAviso(
      context,
      () => moneda == Moneda.ars ? notifier.fijarArs(monto) : notifier.fijarUsd(monto),
      exito: 'Ahorro previo actualizado',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ahorroAsync = ref.watch(ahorroPrevioControladorProvider);

    return ahorroAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('No se pudo leer el ahorro previo', style: TextStyle(color: context.colores.textoSecundario)),
      data: (ahorro) {
        if (!_cargado) {
          _ars.text = ahorro.ars.textoEditable;
          _usd.text = ahorro.usd.textoEditable;
          _cargado = true;
        }
        return Container(
          padding: const EdgeInsets.all(20),
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
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: TemaApp.azul, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('AHORRO PREVIO',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colores.textoSecundario, letterSpacing: 1.1)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'La plata que ya tenías antes de usar la app. Los pesos se suman a tu disponible; los dólares se muestran aparte.',
                style: TextStyle(color: context.colores.textoSecundario, fontSize: 11),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _campo(context, 'PESOS', _ars, Moneda.ars)),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(context, 'DÓLARES', _usd, Moneda.usd)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _campo(BuildContext context, String titulo, TextEditingController controlador, Moneda moneda) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: TextStyle(fontSize: 10, color: context.colores.textoSecundario, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controlador,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FormateadorMonto()],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _guardar(moneda),
          decoration: InputDecoration(
            prefixText: '${moneda.simbolo} ',
            hintText: '0',
            filled: true,
            fillColor: context.colores.superficieAlta,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            suffixIcon: IconButton(
              icon: const Icon(Icons.check, size: 18, color: TemaApp.verde),
              tooltip: 'Guardar',
              onPressed: () => _guardar(moneda),
            ),
          ),
        ),
      ],
    );
  }
}
