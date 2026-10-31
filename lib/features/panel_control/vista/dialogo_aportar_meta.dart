import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/dinero/formateador_monto.dart';
import '../../../core/libro/libro_providers.dart';
import '../../../core/libro/modelo/meta.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../logica/dolar_blue_provider.dart';
import '../logica/metas_provider.dart';

/// Diálogo para aportar pesos del disponible a una meta. Si la meta es en
/// dólares, se convierte al blue de hoy y se guardan dólares.
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
  bool _guardando = false;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _aportar() async {
    final pesos = Dinero.parsear(_monto.text);
    if (pesos == null || !pesos.esPositivo) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresá un monto a aportar')));
      return;
    }
    setState(() => _guardando = true);
    // El servicio valida contra el disponible y el objetivo dentro de la
    // transacción, así no importa si las pantallas tienen datos viejos.
    final ok = await ejecutarConAviso(
      context,
      () => ref.read(metasControladorProvider.notifier).aportar(widget.meta, pesos),
      exito: 'Aportaste ${pesos.formatear()} a "${widget.meta.nombre}"',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.meta;
    final disponible = ref.watch(disponibleProvider).valueOrNull ?? const Dinero.cero();
    final blue = ref.watch(dolarBlueProvider).valueOrNull?.venta;
    final hayCotizacion = blue != null && blue > 0;

    // Lo que falta de la meta, en pesos (para el botón rápido).
    final Dinero? faltaEnPesos = !meta.esUsd
        ? meta.falta
        : (hayCotizacion ? meta.falta.convertir(Moneda.ars, blue) : null);
    final sugerido = faltaEnPesos?.min(disponible);

    final escritos = Dinero.parsear(_monto.text);
    final equivalente = (meta.esUsd && hayCotizacion && escritos != null) ? escritos.convertir(Moneda.usd, blue) : null;

    return AlertDialog(
      title: Text(meta.nombre, style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ahorrado: ${meta.saldo.formatear()} de ${meta.objetivo.formatear()}',
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
              Icon(Icons.account_balance_wallet_outlined, size: 16, color: disponible.esPositivo ? TemaApp.verde : TemaApp.rojo),
              const SizedBox(width: 6),
              Text(
                'Disponible: ${disponible.formatear()}',
                style: TextStyle(color: disponible.esPositivo ? TemaApp.verde : TemaApp.rojo, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _monto,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FormateadorMonto()],
            style: TextStyle(color: context.colores.textoPrimario),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(prefixText: r'$ ', hintText: meta.esUsd ? 'Pesos a aportar' : 'Monto a aportar'),
          ),
          if (meta.esUsd) ...[
            const SizedBox(height: 6),
            Text(
              hayCotizacion
                  ? 'Se guarda como ≈ ${(equivalente ?? const Dinero.cero(Moneda.usd)).formatear()} (blue ${Dinero.desdeUnidades(blue).formatear()})'
                  : 'Esperando la cotización del dólar…',
              style: const TextStyle(color: TemaApp.azul, fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          if (!disponible.esPositivo)
            Text('No tenés plata disponible para asignar. Cargá ingresos o el ahorro previo.',
                style: TextStyle(color: context.colores.textoSecundario, fontSize: 11))
          else
            Wrap(
              spacing: 8,
              children: [
                if (sugerido != null && sugerido.esPositivo)
                  ActionChip(
                    label: Text('Lo que falta (${sugerido.formatear()})'),
                    onPressed: () => setState(() => _monto.text = sugerido.formatear(simbolo: false)),
                  ),
                ActionChip(
                  label: Text('Todo lo disponible (${disponible.formatear()})'),
                  onPressed: () => setState(() => _monto.text = disponible.formatear(simbolo: false)),
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
          onPressed: _guardando ? null : _aportar,
          style: ElevatedButton.styleFrom(backgroundColor: TemaApp.verde, foregroundColor: Colors.white),
          child: const Text('Aportar'),
        ),
      ],
    );
  }
}
