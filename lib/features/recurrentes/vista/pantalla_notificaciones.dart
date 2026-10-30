import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../../panel_control/logica/ahorro_disponible_provider.dart';
import '../logica/cuotas_provider.dart';
import '../logica/gastos_fijos_provider.dart';
import 'dialogo_pagar_cuotas.dart';
import '../../../core/dinero/dinero.dart';

/// Un aviso para el centro de notificaciones.
class _Aviso {
  final IconData icono;
  final Color color;
  final String titulo;
  final String detalle;
  final VoidCallback? onTap;
  const _Aviso(this.icono, this.color, this.titulo, this.detalle, {this.onTap});
}

/// Centro de notificaciones (se abre desde la campana del dashboard).
class PantallaNotificaciones extends ConsumerWidget {
  const PantallaNotificaciones({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disponible = ref.watch(ahorroDisponibleProvider);
    final cuotas = (ref.watch(cuotasControladorProvider).valueOrNull ?? [])
        .where((c) => c.activo && !c.finalizada)
        .toList();
    final fijos = (ref.watch(gastosFijosControladorProvider).valueOrNull ?? [])
        .where((f) => f.activo)
        .toList();

    final avisos = <_Aviso>[];

    // Aviso de ahorros vs cuotas.
    if (cuotas.isNotEmpty) {
      final cancelables = cuotas.where((c) => c.montoRestante <= disponible).toList()
        ..sort((a, b) => a.montoRestante.compareTo(b.montoRestante));

      // Cuántas cuotas mensuales sueltas podés cubrir (de la más barata a la más cara).
      final mensuales = cuotas.map((c) => c.montoCuota).toList()..sort();
      double acum = 0;
      int cuotasCubiertas = 0;
      for (final m in mensuales) {
        if (acum + m <= disponible) {
          acum += m;
          cuotasCubiertas++;
        }
      }

      if (cancelables.isNotEmpty) {
        avisos.add(_Aviso(Icons.savings, TemaApp.verde, 'Podés cancelar deudas',
            'Con tus ahorros (${Dinero.desdeUnidades(disponible).formatear()}) podés cancelar por completo ${cancelables.length} de ${cuotas.length}: ${cancelables.map((c) => c.nombre).join(', ')}. Tocá para pagar.',
            onTap: () => DialogoPagarCuotas.mostrar(context)));
      }
      if (cuotasCubiertas > 0) {
        avisos.add(_Aviso(Icons.payments_outlined, TemaApp.azul, 'Cuotas del mes',
            'Te alcanza para pagar $cuotasCubiertas ${cuotasCubiertas == 1 ? 'cuota mensual' : 'cuotas mensuales'} de las que tenés en curso. Tocá para pagar.',
            onTap: () => DialogoPagarCuotas.mostrar(context)));
      } else {
        final masBarata = cuotas.reduce((a, b) => a.montoCuota <= b.montoCuota ? a : b);
        avisos.add(_Aviso(Icons.info_outline, context.colores.textoSecundario, 'Cuotas',
            'Todavía no te alcanza para pagar una cuota. La más barata es "${masBarata.nombre}" (${Dinero.desdeUnidades(masBarata.montoCuota).formatear()}).'));
      }
    }

    // Aviso de fijos que se debitan este mes.
    if (fijos.isNotEmpty) {
      final total = fijos.fold<double>(0, (s, f) => s + f.monto);
      final proximos = (fijos.toList()..sort((a, b) => a.diaDebito.compareTo(b.diaDebito)))
          .map((f) => '${f.nombre} (día ${f.diaDebito})')
          .join(', ');
      avisos.add(_Aviso(Icons.event_repeat, TemaApp.rojo, 'Gastos fijos del mes',
          'Este mes se debitan ${Dinero.desdeUnidades(total).formatear()} en fijos: $proximos. Confirmalos en "Pendientes del mes".'));
    }

    return Scaffold(
      backgroundColor: context.colores.fondo,
      appBar: AppBar(
        backgroundColor: context.colores.fondo,
        title: Text('Notificaciones', style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.colores.textoPrimario),
      ),
      body: avisos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 56, color: context.colores.textoSecundario),
                  const SizedBox(height: 12),
                  Text('No hay novedades por ahora', style: TextStyle(color: context.colores.textoSecundario)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: avisos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final a = avisos[i];
                return Material(
                  color: context.colores.superficie,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: a.onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.colores.borde),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(a.icono, color: a.color, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.titulo, style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(a.detalle, style: TextStyle(color: context.colores.textoSecundario, fontSize: 13)),
                              ],
                            ),
                          ),
                          if (a.onTap != null)
                            Icon(Icons.chevron_right, color: context.colores.textoSecundario, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
