import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../logica/gastos_fijos_provider.dart';
import '../modelo/gasto_fijo.dart';
import 'dialogo_gasto_fijo.dart';
import '../../../core/dinero/dinero.dart';

/// Pantalla de gestión de gastos fijos mensuales.
class PantallaFijos extends ConsumerWidget {
  const PantallaFijos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fijosAsync = ref.watch(gastosFijosControladorProvider);

    return Scaffold(
      backgroundColor: context.colores.fondo,
      appBar: AppBar(
        title: Text('Gastos Fijos', style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
        backgroundColor: context.colores.fondo,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => DialogoGastoFijo.mostrar(context),
        backgroundColor: TemaApp.verde,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo fijo'),
      ),
      body: fijosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: TemaApp.rojo))),
        data: (fijos) {
          if (fijos.isEmpty) {
            return _VacioFijos(colores: context.colores);
          }
          final totalActivo = fijos
              .where((f) => f.activo)
              .fold<double>(0, (s, f) => s + f.monto);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colores.superficie,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colores.borde),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total fijo mensual', style: TextStyle(color: context.colores.textoSecundario, fontWeight: FontWeight.bold)),
                    Text(Dinero.desdeUnidades(totalActivo).formatear(), style: const TextStyle(color: TemaApp.rojo, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...fijos.map((f) => _TarjetaFijo(fijo: f)),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

class _TarjetaFijo extends ConsumerWidget {
  final GastoFijo fijo;
  const _TarjetaFijo({required this.fijo});

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar gasto fijo', style: TextStyle(color: ctx.colores.textoPrimario)),
        content: Text('¿Seguro que querés eliminar "${fijo.nombre}"?', style: TextStyle(color: ctx.colores.textoSecundario)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: ctx.colores.textoSecundario))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: TemaApp.rojo, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (ok == true) ref.read(gastosFijosControladorProvider.notifier).eliminar(fijo.id!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colores.borde),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fijo.nombre, style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${Dinero.desdeUnidades(fijo.monto).formatear()} · se debita el día ${fijo.diaDebito}', style: TextStyle(color: context.colores.textoSecundario, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: fijo.activo,
            activeThumbColor: TemaApp.verde,
            onChanged: (_) => ref.read(gastosFijosControladorProvider.notifier).alternarActivo(fijo),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: context.colores.textoSecundario, size: 20),
            onPressed: () => DialogoGastoFijo.mostrar(context, aEditar: fijo),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: TemaApp.rojo, size: 20),
            onPressed: () => _confirmarEliminar(context, ref),
          ),
        ],
      ),
    );
  }
}

class _VacioFijos extends StatelessWidget {
  final ColoresApp colores;
  const _VacioFijos({required this.colores});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 56, color: colores.textoSecundario),
          const SizedBox(height: 16),
          Text('Sin gastos fijos', style: TextStyle(color: colores.textoPrimario, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Cargá tus servicios, alquiler o impuestos para descontarlos cada mes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colores.textoSecundario, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
