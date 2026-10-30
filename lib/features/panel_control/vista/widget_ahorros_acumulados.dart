import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/utilidades/formateador_miles.dart';
import '../logica/ahorros_provider.dart';
import '../logica/dolar_blue_provider.dart';

/// Widget que muestra los ahorros acumulados (ARS + USD) con
/// conversión en tiempo real usando el dólar blue.
class WidgetAhorrosAcumulados extends ConsumerStatefulWidget {
  const WidgetAhorrosAcumulados({super.key});

  @override
  ConsumerState<WidgetAhorrosAcumulados> createState() => _WidgetAhorrosAcumuladosState();
}

class _WidgetAhorrosAcumuladosState extends ConsumerState<WidgetAhorrosAcumulados> {
  final _controladorArs = TextEditingController();
  final _controladorUsd = TextEditingController();
  bool _editandoArs = false;
  bool _editandoUsd = false;

  @override
  void dispose() {
    _controladorArs.dispose();
    _controladorUsd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ahorrosAsync = ref.watch(ahorrosControladorProvider);
    final dolarAsync = ref.watch(dolarBlueProvider);

    return ahorrosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
      data: (ahorros) {
        final dolar = dolarAsync.valueOrNull;
        final cotizacionVenta = dolar?['venta'] ?? 0.0;

        // Calcular total acumulado
        final usdEnArs = ahorros.ahorroPrevioUsd * cotizacionVenta;
        final totalAcumulado = ahorros.ahorroPrevioArs + usdEnArs;

        // Sincronizar controladores si no estamos editando
        if (!_editandoArs) {
          final textoArs = ahorros.ahorroPrevioArs > 0
              ? NumberFormat('#,##0.##', 'es_AR').format(ahorros.ahorroPrevioArs)
              : '';
          if (_controladorArs.text != textoArs) {
            _controladorArs.text = textoArs;
          }
        }
        if (!_editandoUsd) {
          final textoUsd = ahorros.ahorroPrevioUsd > 0
              ? NumberFormat('#,##0.##', 'es_AR').format(ahorros.ahorroPrevioUsd)
              : '';
          if (_controladorUsd.text != textoUsd) {
            _controladorUsd.text = textoUsd;
          }
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
                  Text('AHORRO PREVIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colores.textoSecundario, letterSpacing: 1.1)),
                ],
              ),
              const SizedBox(height: 4),
              Text('La plata que ya tenías ahorrada antes de usar la app. Se suma a tu disponible.',
                  style: TextStyle(color: context.colores.textoSecundario, fontSize: 11)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AHORRO PREVIO ARS', style: TextStyle(fontSize: 10, color: context.colores.textoSecundario, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _controladorArs,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FormateadorMiles()],
                          onTap: () => setState(() => _editandoArs = true),
                          onSubmitted: (valor) {
                            _editandoArs = false;
                            final monto = double.tryParse(valor.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
                            ref.read(ahorrosControladorProvider.notifier).actualizarArs(monto);
                          },
                          onTapOutside: (_) {
                            if (_editandoArs) {
                              _editandoArs = false;
                              final monto = double.tryParse(
                                _controladorArs.text.replaceAll('.', '').replaceAll(',', '.'),
                              ) ?? 0;
                              ref.read(ahorrosControladorProvider.notifier).actualizarArs(monto);
                            }
                          },
                          decoration: InputDecoration(
                            prefixText: '\$ ',
                            hintText: '0',
                            filled: true,
                            fillColor: context.colores.superficieAlta,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AHORRO PREVIO USD', style: TextStyle(fontSize: 10, color: context.colores.textoSecundario, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _controladorUsd,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FormateadorMiles()],
                          onTap: () => setState(() => _editandoUsd = true),
                          onSubmitted: (valor) {
                            _editandoUsd = false;
                            final monto = double.tryParse(valor.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
                            ref.read(ahorrosControladorProvider.notifier).actualizarUsd(monto);
                          },
                          onTapOutside: (_) {
                            if (_editandoUsd) {
                              _editandoUsd = false;
                              final monto = double.tryParse(
                                _controladorUsd.text.replaceAll('.', '').replaceAll(',', '.'),
                              ) ?? 0;
                              ref.read(ahorrosControladorProvider.notifier).actualizarUsd(monto);
                            }
                          },
                          decoration: InputDecoration(
                            prefixText: 'u\$s ',
                            hintText: '0',
                            filled: true,
                            fillColor: context.colores.superficieAlta,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total acumulado ARS', style: TextStyle(color: context.colores.textoSecundario, fontSize: 10)),
                    Text(
                      '\$${NumberFormat('#,##0.##', 'es_AR').format(totalAcumulado)}',
                      style: const TextStyle(color: TemaApp.verde, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
