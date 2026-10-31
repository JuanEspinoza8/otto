import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tema/tema_app.dart';
import '../../panel_control/logica/dashboard_provider.dart';
import '../../../core/ui/acciones.dart';
import '../logica/categorias_provider.dart';
import '../logica/presupuesto.dart';
import '../modelo/categoria.dart';
import '../../../core/dinero/dinero.dart';
import '../../../core/dinero/formateador_monto.dart';

/// Sección de presupuestos por categoría: muestra el progreso de gasto del mes
/// contra el límite de cada rubro y permite asignar/editar esos límites.
class SeccionPresupuestos extends ConsumerWidget {
  const SeccionPresupuestos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categorias = ref.watch(categoriasControladorProvider).valueOrNull ?? [];
    // Gastado del mes POR CATEGORÍA, calculado sobre la base (no sobre la lista
    // paginada de 30 movimientos, que subcontaba).
    final gastosPorId = ref.watch(gastosPorCategoriaProvider).valueOrNull ?? const <int, Dinero>{};

    final conLimite = categorias.where((c) => c.esGasto && c.presupuestoLimite.esPositivo).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colores.superficie,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colores.borde),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: TemaApp.verde, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Presupuestos por categoría',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colores.textoPrimario),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (conLimite.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Todavía no asignaste límites. Tocá "Asignar límite" para ponerle un tope de gasto a tus rubros.',
                  style: TextStyle(color: context.colores.textoSecundario, fontSize: 13),
                ),
              )
            else
              ...conLimite.map((categoria) {
                final gastado = gastosPorId[categoria.id] ?? const Dinero.cero();
                final limite = categoria.presupuestoLimite;
                final ratio = gastado.centavos / limite.centavos;
                final nivel = nivelPresupuesto(gastado, limite);
                final color = switch (nivel) {
                  NivelPresupuesto.normal => TemaApp.verde,
                  NivelPresupuesto.alerta => TemaApp.amarillo,
                  NivelPresupuesto.excedido => TemaApp.rojo,
                };

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(categoria.nombre, style: TextStyle(fontWeight: FontWeight.bold, color: context.colores.textoPrimario)),
                          Text('${gastado.porcentajeDe(limite)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        backgroundColor: context.colores.superficieAlta,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        switch (nivel) {
                          NivelPresupuesto.normal => '${gastado.formatear()} de ${limite.formatear()}',
                          NivelPresupuesto.alerta => '${gastado.formatear()} de ${limite.formatear()} · cerca del límite',
                          NivelPresupuesto.excedido =>
                            '${gastado.formatear()} de ${limite.formatear()} · te pasaste por ${(gastado - limite).formatear()}',
                        },
                        style: TextStyle(
                          fontSize: 12,
                          color: nivel == NivelPresupuesto.normal ? context.colores.textoSecundario : color,
                          fontWeight: nivel == NivelPresupuesto.normal ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _abrirAsignarLimite(context),
              icon: const Icon(Icons.tune, size: 18, color: TemaApp.verde),
              label: const Text('Asignar límite', style: TextStyle(color: TemaApp.verde, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: TemaApp.verde)),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirAsignarLimite(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colores.superficie,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _HojaLimites(),
    );
  }
}

/// Hoja inferior para asignar/editar los límites de las categorías de gasto.
class _HojaLimites extends ConsumerWidget {
  const _HojaLimites();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categorias = (ref.watch(categoriasControladorProvider).valueOrNull ?? [])
        .where((c) => c.tipo == 'gasto')
        .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asignar límite mensual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colores.textoPrimario)),
            const SizedBox(height: 4),
            Text('Tocá una categoría para ponerle (o sacarle) un tope de gasto.', style: TextStyle(fontSize: 12, color: context.colores.textoSecundario)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: categorias.map((c) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.nombre, style: TextStyle(color: context.colores.textoPrimario)),
                    trailing: Text(
                      c.presupuestoLimite.esPositivo ? c.presupuestoLimite.formatear() : 'Sin límite',
                      style: TextStyle(
                        color: c.presupuestoLimite.esPositivo ? TemaApp.verde : context.colores.textoSecundario,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => _editarLimite(context, ref, c),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarLimite(BuildContext context, WidgetRef ref, Categoria cat) async {
    final controlador = TextEditingController(
      text: cat.presupuestoLimite.textoEditable,
    );
    final nuevo = await showDialog<Dinero>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Límite de ${cat.nombre}', style: TextStyle(color: ctx.colores.textoPrimario)),
        content: TextField(
          controller: controlador,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FormateadorMonto()],
          style: TextStyle(color: ctx.colores.textoPrimario),
          decoration: const InputDecoration(prefixText: '\$ ', hintText: 'Monto mensual (0 = sin límite)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: TextStyle(color: ctx.colores.textoSecundario))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, Dinero.parsear(controlador.text) ?? const Dinero.cero());
            },
            child: const Text('Guardar', style: TextStyle(color: TemaApp.verde, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (nuevo != null && context.mounted) {
      await ejecutarConAviso(
        context,
        () => ref.read(categoriasControladorProvider.notifier).actualizar(cat.copiaCon(presupuestoLimite: nuevo)),
      );
    }
  }
}
