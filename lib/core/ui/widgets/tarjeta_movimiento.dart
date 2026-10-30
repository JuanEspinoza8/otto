import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../tema/tema_app.dart';
import '../../utilidades/mapeador_iconos.dart';
import '../../../features/movimientos/modelo/movimiento.dart';
import '../../../features/movimientos/vista/dialogo_editar_movimiento.dart';
import '../../../features/categorias/modelo/categoria.dart';

class TarjetaMovimiento extends StatelessWidget {
  final Movimiento movimiento;
  final Categoria categoria;
  final VoidCallback alEliminar;

  const TarjetaMovimiento({
    super.key,
    required this.movimiento,
    required this.categoria,
    required this.alEliminar,
  });

  @override
  Widget build(BuildContext context) {
    // Formatear monto según regla de moneda en Argentina (sin decimales para
    // que montos grandes no desborden la tarjeta).
    // "$" adelante (consistente con el resto) y hasta 2 decimales si los tiene.
    final montoFormateado = '\$${NumberFormat('#,##0.##', 'es_AR').format(movimiento.monto)}';
    final esIngreso = movimiento.tipo == 'ingreso';
    final esAhorro = movimiento.tipo == 'ahorro';
    // Color e ícono del monto: verde ingreso, azul ahorro, rojo gasto.
    final colorMonto = esIngreso ? TemaApp.verde : (esAhorro ? TemaApp.azul : TemaApp.rojo);
    final signoMonto = esIngreso ? '+' : (esAhorro ? '→ ' : '-');

    // Fecha exacta del movimiento (día y mes), como en el diseño de referencia.
    final fechaFormateada = DateFormat('d MMM', 'es').format(movimiento.fecha);

    final colorCategoria = Color(int.parse(categoria.colorHex));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colores.borde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono de la categoría
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorCategoria.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(MapeadorIconos.obtenerIcono(categoria.icono), color: colorCategoria, size: 22),
          ),
          const SizedBox(width: 12),
          // Concepto + (categoría · fecha). Ocupa todo el espacio libre.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  movimiento.descripcion?.isNotEmpty == true
                      ? movimiento.descripcion!
                      : categoria.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.colores.textoPrimario,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${categoria.nombre} · $fechaFormateada',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: context.colores.textoSecundario),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Monto en su propia línea (se ve completo) + acciones debajo.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$signoMonto$montoFormateado',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorMonto,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Los aportes de ahorro no se editan: se borran para
                  // deshacerlos y así vuelve la plata al disponible.
                  if (!esAhorro)
                    _BotonAccion(
                      icono: Icons.edit_outlined,
                      color: context.colores.textoSecundario,
                      tooltip: 'Editar',
                      onTap: () => DialogoEditarMovimiento.mostrar(context, movimiento),
                    ),
                  _BotonAccion(
                    icono: Icons.delete_outline,
                    color: TemaApp.rojo,
                    tooltip: 'Borrar',
                    onTap: () => _confirmarBorrado(context),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Pide confirmación antes de borrar el movimiento.
  Future<void> _confirmarBorrado(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Borrar movimiento', style: TextStyle(color: ctx.colores.textoPrimario)),
        content: Text(
          '¿Seguro que querés borrar "${movimiento.descripcion?.isNotEmpty == true ? movimiento.descripcion : categoria.nombre}"? Esta acción no se puede deshacer.',
          style: TextStyle(color: ctx.colores.textoSecundario),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: ctx.colores.textoSecundario)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar', style: TextStyle(color: TemaApp.rojo, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmar == true) alEliminar();
  }
}

/// Botón compacto de acción (editar/borrar) para la tarjeta de movimiento.
class _BotonAccion extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _BotonAccion({
    required this.icono,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icono, color: color, size: 20),
        ),
      ),
    );
  }
}
