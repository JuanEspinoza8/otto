import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/tema/tema_app.dart';
import '../../panel_control/logica/ahorro_disponible_provider.dart';
import '../logica/cuotas_provider.dart';
import '../modelo/cuota.dart';
import 'dialogo_cuota.dart';

/// Pantalla de gestión de cuotas en pago.
class PantallaCuotas extends ConsumerWidget {
  const PantallaCuotas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuotasAsync = ref.watch(cuotasControladorProvider);
    final formato = NumberFormat('#,##0.##', 'es_AR');

    return Scaffold(
      backgroundColor: context.colores.fondo,
      appBar: AppBar(
        title: Text('Cuotas', style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
        backgroundColor: context.colores.fondo,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => DialogoCuota.mostrar(context),
        backgroundColor: TemaApp.verde,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva cuota'),
      ),
      body: cuotasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: TemaApp.rojo))),
        data: (cuotas) {
          if (cuotas.isEmpty) {
            return _VacioCuotas(colores: context.colores);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TarjetaAhorroVsCuotas(cuotas: cuotas, formato: formato),
              ...cuotas.map((c) => _TarjetaCuota(cuota: c, formato: formato)),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

/// Muestra si los ahorros disponibles alcanzan para cancelar cuotas.
class _TarjetaAhorroVsCuotas extends ConsumerWidget {
  final List<Cuota> cuotas;
  final NumberFormat formato;
  const _TarjetaAhorroVsCuotas({required this.cuotas, required this.formato});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activas = cuotas.where((c) => c.activo && !c.finalizada).toList();
    if (activas.isEmpty) return const SizedBox.shrink();

    final disponible = ref.watch(ahorroDisponibleProvider);
    final cancelables = activas.where((c) => c.montoRestante <= disponible).toList()
      ..sort((a, b) => a.montoRestante.compareTo(b.montoRestante));

    String mensaje;
    if (cancelables.isNotEmpty) {
      mensaje = 'Te alcanza para cancelar por completo: ${cancelables.map((c) => c.nombre).join(', ')}.';
    } else {
      final masBarata = activas.reduce((a, b) => a.montoRestante <= b.montoRestante ? a : b);
      final falta = masBarata.montoRestante - disponible;
      mensaje = 'Todavía no te alcanza para cancelar una cuota entera. La más cercana es "${masBarata.nombre}" (te faltan \$${formato.format(falta)}).';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.azul.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 18, color: TemaApp.azul),
              const SizedBox(width: 8),
              Text('Ahorros disponibles: \$${formato.format(disponible)}',
                  style: const TextStyle(color: TemaApp.azul, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Text(mensaje, style: TextStyle(color: context.colores.textoSecundario, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TarjetaCuota extends ConsumerWidget {
  final Cuota cuota;
  final NumberFormat formato;
  const _TarjetaCuota({required this.cuota, required this.formato});

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar cuota', style: TextStyle(color: ctx.colores.textoPrimario)),
        content: Text('¿Seguro que querés eliminar "${cuota.nombre}"? Los pagos que ya registraste quedan en tu historial.', style: TextStyle(color: ctx.colores.textoSecundario)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: ctx.colores.textoSecundario))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: TemaApp.rojo, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (ok == true) ref.read(cuotasControladorProvider.notifier).eliminar(cuota.id!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finalizada = cuota.finalizada;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Text(cuota.nombre, style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              if (finalizada)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: TemaApp.verde.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Pagada', style: TextStyle(color: TemaApp.verde, fontSize: 11, fontWeight: FontWeight.bold)),
                )
              else
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: context.colores.textoSecundario, size: 20),
                  onPressed: () => DialogoCuota.mostrar(context, aEditar: cuota),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: TemaApp.rojo, size: 20),
                onPressed: () => _confirmarEliminar(context, ref),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\$${formato.format(cuota.montoCuota)} · cuota ${cuota.cuotasPagadas}/${cuota.totalCuotas} · día ${cuota.diaDebito}',
            style: TextStyle(color: context.colores.textoSecundario, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: cuota.porcentaje / 100,
              minHeight: 6,
              backgroundColor: context.colores.superficieAlta,
              valueColor: AlwaysStoppedAnimation<Color>(finalizada ? TemaApp.verde : TemaApp.azul),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            finalizada
                ? 'Terminada · ya no se descuenta'
                : 'Restan ${cuota.cuotasRestantes} cuotas · \$${formato.format(cuota.montoRestante)}',
            style: TextStyle(color: context.colores.textoSecundario, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _VacioCuotas extends StatelessWidget {
  final ColoresApp colores;
  const _VacioCuotas({required this.colores});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_outlined, size: 56, color: colores.textoSecundario),
          const SizedBox(height: 16),
          Text('Sin cuotas', style: TextStyle(color: colores.textoPrimario, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Cargá las cuotas que estás pagando. Cuando termines de pagarlas, dejan de descontarse solas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colores.textoSecundario, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
