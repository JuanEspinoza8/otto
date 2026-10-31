import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/libro/libro_providers.dart';
import '../../../core/libro/modelo/movimiento.dart';
import '../../../core/ui/acciones.dart';
import '../../../core/ui/widgets/presentacion_movimiento.dart';
import '../../../core/ui/widgets/tarjeta_movimiento.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../../panel_control/logica/metas_provider.dart';
import '../logica/movimientos_provider.dart';

/// Tarjeta de un movimiento con su categoría o meta resuelta y el borrado.
class FilaMovimiento extends ConsumerWidget {
  const FilaMovimiento({super.key, required this.movimiento});

  final Movimiento movimiento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categorias = ref.watch(categoriasControladorProvider).valueOrNull ?? const [];
    final cuentas = ref.watch(cuentasProvider).valueOrNull ?? const [];
    final metas = ref.watch(metasControladorProvider).valueOrNull ?? const [];
    final presentacion = PresentacionMovimiento.de(
      movimiento,
      categorias: categorias,
      cuentas: {for (final c in cuentas) c.id: c},
      metas: metas,
    );
    return TarjetaMovimiento(
      movimiento: movimiento,
      presentacion: presentacion,
      alEliminar: () => ejecutarConAviso(
        context,
        () => ref.read(movimientosControladorProvider.notifier).eliminar(movimiento.id!),
        exito: 'Movimiento borrado',
      ),
    );
  }
}
