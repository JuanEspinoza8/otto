import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../logica/planes_provider.dart';
import '../modelo/plan.dart';

/// Pendientes del mes seleccionado (sueldo, gastos fijos y cuotas).
///
/// Cada pendiente se confirma una sola vez: el botón se deshabilita mientras
/// guarda y la base rechaza un segundo período igual. "Ya lo cargué" lo
/// resuelve sin crear otro movimiento (si se cargó a mano).
class WidgetPendientesMes extends ConsumerStatefulWidget {
  const WidgetPendientesMes({super.key});

  @override
  ConsumerState<WidgetPendientesMes> createState() => _WidgetPendientesMesState();
}

class _WidgetPendientesMesState extends ConsumerState<WidgetPendientesMes> {
  final Set<String> _enCurso = {};

  String _clave(Pendiente p) => '${p.plan.id}:${p.periodo}';

  Future<void> _resolver(Pendiente p, {required bool crearMovimiento}) async {
    setState(() => _enCurso.add(_clave(p)));
    final notifier = ref.read(planesControladorProvider.notifier);
    await ejecutarConAviso(
      context,
      () => crearMovimiento ? notifier.confirmar(p) : notifier.marcarSinMovimiento(p),
    );
    if (mounted) setState(() => _enCurso.remove(_clave(p)));
  }

  Future<void> _confirmarTodos(List<Pendiente> pendientes) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar todo', style: TextStyle(color: ctx.colores.textoPrimario)),
        content: Text(
          'Se van a registrar:\n${pendientes.map((p) => '• ${p.descripcion}: ${p.monto.formatear()}').join('\n')}\n\n'
          'Si alguno ya lo cargaste a mano, usá "Ya lo cargué" en ese en vez de confirmar todo.',
          style: TextStyle(color: ctx.colores.textoSecundario),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar', style: TextStyle(color: TemaApp.verde, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    for (final p in pendientes) {
      if (!mounted) return;
      await _resolver(p, crearMovimiento: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = ref.watch(pendientesMesProvider).valueOrNull ?? const <Pendiente>[];
    if (pendientes.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
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
              const Text('🗓️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('PENDIENTES DEL MES',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colores.textoSecundario, letterSpacing: 1.1)),
              ),
              if (pendientes.length > 1)
                TextButton(
                  onPressed: _enCurso.isEmpty ? () => _confirmarTodos(pendientes) : null,
                  child: const Text('Confirmar todo', style: TextStyle(color: TemaApp.verde, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final p in pendientes) _fila(context, p),
        ],
      ),
    );
  }

  Widget _fila(BuildContext context, Pendiente p) {
    final enCurso = _enCurso.contains(_clave(p));
    final color = p.plan.esIngreso ? TemaApp.verde : TemaApp.rojo;
    return Padding(
      key: ValueKey(_clave(p)),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(p.plan.esIngreso ? Icons.arrow_downward : Icons.arrow_upward, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(p.descripcion, style: TextStyle(color: context.colores.textoPrimario, fontSize: 13))),
          Text(
            '${p.plan.esIngreso ? '+' : '-'}${p.monto.formatear()}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          PopupMenuButton<bool>(
            enabled: !enCurso,
            tooltip: 'Más opciones',
            icon: Icon(Icons.more_vert, size: 18, color: context.colores.textoSecundario),
            onSelected: (crear) => _resolver(p, crearMovimiento: crear),
            itemBuilder: (_) => const [
              PopupMenuItem(value: false, child: Text('Ya lo cargué')),
            ],
          ),
          InkWell(
            onTap: enCurso ? null : () => _resolver(p, crearMovimiento: true),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: TemaApp.verde.withValues(alpha: enCurso ? 0.05 : 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: enCurso
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: TemaApp.verde))
                  : const Text('Confirmar', style: TextStyle(color: TemaApp.verde, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
