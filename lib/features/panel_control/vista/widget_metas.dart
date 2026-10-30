import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/ui/widgets/mascota_otto.dart';
import '../logica/metas_provider.dart';
import '../../../core/utilidades/mapeador_iconos.dart';
import 'dialogo_nueva_meta.dart';
import 'dialogo_acciones_meta.dart';

/// Widget que muestra las metas de ahorro con la mascota Monedita y progreso.
class WidgetMetas extends ConsumerWidget {
  const WidgetMetas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metasAsync = ref.watch(metasControladorProvider);
    final progresoMeta = ref.watch(progresoMetaTotalProvider);

    return metasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
      data: (metasConSubmetas) {
        final tieneMetas = metasConSubmetas.isNotEmpty;
        final porcentaje = progresoMeta['porcentaje'] ?? 0;
        final montoActual = progresoMeta['montoActual'] ?? 0;

        // Mensaje de ánimo de Otto según el progreso
        String mensaje;
        if (!tieneMetas) {
          mensaje = 'Creá tu primera\nmeta de ahorro';
        } else if (porcentaje >= 100) {
          mensaje = '¡Lo lograste!\n🎉🎉';
        } else if (porcentaje >= 80) {
          mensaje = '¡Ya casi\nllegás! 🚀';
        } else if (porcentaje >= 50) {
          mensaje = '¡Bien! Estás\nahorrando 🎉';
        } else if (porcentaje > 0) {
          mensaje = '¡Seguí así!\nVas bien 💪';
        } else {
          mensaje = 'Empezá a\nahorrar hoy';
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.colores.superficie,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colores.borde),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        const MascotaOttoAnimada(tamano: 104),
                        const SizedBox(height: 8),
                        Text('OTTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.colores.textoSecundario)),
                        Text(
                          mensaje,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: TemaApp.verde, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 100, color: context.colores.borde),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🎯 Meta de ahorro total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.colores.textoPrimario)),
                          const SizedBox(height: 4),
                          Text('Progreso de todas tus metas', style: TextStyle(color: context.colores.textoSecundario, fontSize: 10)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ahorraste \$${NumberFormat('#,##0.##', 'es_AR').format(montoActual)}',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.colores.textoPrimario),
                              ),
                              Text(
                                '${porcentaje.floor()}%',
                                style: const TextStyle(color: TemaApp.verde, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: porcentaje / 100,
                              minHeight: 6,
                              backgroundColor: context.colores.superficieAlta,
                              valueColor: const AlwaysStoppedAnimation<Color>(TemaApp.verde),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (tieneMetas) ...[
                const SizedBox(height: 16),
                ...metasConSubmetas.entries.expand((entry) {
                  final meta = entry.key;
                  final submetas = entry.value;

                  if (submetas.isEmpty) {
                    // Si la meta no tiene submetas, mostrarla directamente.
                    // Al tocarla se abre el diálogo para aportar/eliminar.
                    return [
                      GestureDetector(
                        onTap: () => DialogoAccionesMeta.mostrar(context, meta),
                        child: _TarjetaSubmeta(
                          icono: MapeadorIconos.obtenerIcono(meta.icono),
                          nombre: meta.nombre,
                          montoActual: meta.montoActual,
                          montoObjetivo: meta.montoObjetivo,
                          porcentaje: meta.porcentajeProgreso.toInt(),
                          mostrarFlecha: true,
                          simbolo: meta.esUsd ? 'U\$D' : '\$',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ];
                  }

                  // Si tiene submetas, mostrar cada una
                  return submetas.expand((sub) => [
                    _TarjetaSubmeta(
                      icono: MapeadorIconos.obtenerIcono(sub.icono),
                      nombre: sub.nombre,
                      montoActual: sub.montoActual,
                      montoObjetivo: sub.montoObjetivo,
                      porcentaje: sub.porcentajeProgreso.toInt(),
                      simbolo: meta.esUsd ? 'U\$D' : '\$',
                    ),
                    const SizedBox(height: 8),
                  ]);
                }),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => DialogoNuevaMeta.mostrar(context),
                  icon: const Icon(Icons.add, size: 18, color: TemaApp.verde),
                  label: Text(
                    tieneMetas ? 'Nueva meta' : 'Crear meta de ahorro',
                    style: const TextStyle(color: TemaApp.verde, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: TemaApp.verde),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TarjetaSubmeta extends StatelessWidget {
  final IconData icono;
  final String nombre;
  final double montoActual;
  final double montoObjetivo;
  final int porcentaje;
  final bool mostrarFlecha;
  final String simbolo;

  const _TarjetaSubmeta({
    required this.icono,
    required this.nombre,
    required this.montoActual,
    required this.montoObjetivo,
    required this.porcentaje,
    this.mostrarFlecha = false,
    this.simbolo = '\$',
  });

  String _formatearMonto(double monto) {
    if (monto >= 1000) {
      return '$simbolo${(monto / 1000).toStringAsFixed(0)}K';
    }
    return '$simbolo${NumberFormat('#,##0.##', 'es_AR').format(monto)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: context.colores.superficieAlta, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icono, color: TemaApp.azul, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colores.textoPrimario)),
                Text(
                  '${_formatearMonto(montoActual)} / ${_formatearMonto(montoObjetivo)}',
                  style: TextStyle(color: context.colores.textoSecundario, fontSize: 10),
                ),
              ],
            ),
          ),
          Text('$porcentaje%', style: const TextStyle(color: TemaApp.verde, fontWeight: FontWeight.bold, fontSize: 12)),
          if (mostrarFlecha) ...[
            const SizedBox(width: 6),
            const Icon(Icons.add_circle, color: TemaApp.verde, size: 18),
          ],
        ],
      ),
    );
  }
}
