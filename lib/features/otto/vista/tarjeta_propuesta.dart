import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../../../core/utilidades/mapeador_iconos.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../../categorias/modelo/categoria.dart';
import '../logica/otto_provider.dart';

/// Tarjeta de un movimiento que entendió Otto, con categoría editable.
///
/// Si coincide por nombre con un gasto fijo que todavía no se pagó este mes,
/// ofrece contarlo como ese pago (sin marcar por defecto). Nunca reemplaza
/// un movimiento ya registrado.
class TarjetaPropuesta extends ConsumerStatefulWidget {
  const TarjetaPropuesta({super.key, required this.propuesta});

  final PropuestaOtto propuesta;

  @override
  ConsumerState<TarjetaPropuesta> createState() => _TarjetaPropuestaState();
}

class _TarjetaPropuestaState extends ConsumerState<TarjetaPropuesta> {
  int? _categoriaId;
  bool _conciliar = false;
  bool _actualizarFijo = false;
  bool _guardando = false;

  Future<void> _confirmar() async {
    setState(() => _guardando = true);
    final ok = await ejecutarConAviso(
      context,
      () => ref.read(ottoControladorProvider.notifier).confirmar(
            widget.propuesta,
            categoriaId: _categoriaId,
            conciliarConFijo: _conciliar,
            actualizarMontoFijo: _conciliar && _actualizarFijo,
          ),
      exito: '✅ Movimiento registrado',
    );
    if (!ok && mounted) setState(() => _guardando = false);
  }

  void _elegirCategoria(List<Categoria> candidatas) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Elegí la categoría', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ctx.colores.textoPrimario)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in candidatas)
                  ActionChip(
                    avatar: Icon(MapeadorIconos.obtenerIcono(c.icono), size: 16, color: Color(int.parse(c.colorHex))),
                    label: Text(c.nombre),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _categoriaId = c.id);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.propuesta;
    final s = p.sugerencia;
    final colorTipo = s.esGasto ? TemaApp.rojo : TemaApp.verde;
    final candidatas = (ref.watch(categoriasControladorProvider).valueOrNull ?? const <Categoria>[])
        .where((c) => c.tipo == s.tipo)
        .toList();
    final elegida = candidatas.where((c) => c.id == (_categoriaId ?? s.categoriaId)).firstOrNull;
    final texto = TextStyle(color: context.colores.textoSecundario, fontSize: 12);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colores.superficieAlta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorTipo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: colorTipo, borderRadius: BorderRadius.circular(8)),
                child: Text(s.esGasto ? 'Gasto' : 'Ingreso',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.horas != null && elegida?.nombre == 'Horas extras' ? '${s.horas} horas extra' : s.monto.formatear(),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.colores.textoPrimario),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(s.descripcion, style: texto),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _elegirCategoria(candidatas),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text('Categoría: ', style: texto),
                Text(elegida?.nombre ?? 'Elegir',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colores.textoPrimario)),
                const Text('· Tocá para cambiar', style: TextStyle(color: TemaApp.verde, fontSize: 10, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          if (p.fijo != null) ...[
            const SizedBox(height: 8),
            if (p.fijoAplicadoEsteMes)
              Text('"${p.fijo!.nombre}" ya está pagado este mes: esto se registra como un gasto aparte.',
                  style: const TextStyle(fontSize: 11, color: TemaApp.azul))
            else ...[
              _casilla('Es el pago de "${p.fijo!.nombre}" de este mes', _conciliar, (v) => setState(() => _conciliar = v)),
              if (_conciliar && p.difiereDelFijo)
                _casilla(
                  'Cambiar el fijo de ${p.fijo!.monto.formatear()} a ${s.monto.formatear()} para los próximos meses',
                  _actualizarFijo,
                  (v) => setState(() => _actualizarFijo = v),
                ),
            ],
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _confirmar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaApp.verde,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('✓ Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _guardando ? null : () => ref.read(ottoControladorProvider.notifier).descartar(p),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: context.colores.borde),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Descartar', style: TextStyle(color: context.colores.textoSecundario)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _casilla(String texto, bool valor, ValueChanged<bool> alCambiar) {
    return Row(
      children: [
        Checkbox(
          value: valor,
          onChanged: (v) => alCambiar(v ?? false),
          visualDensity: VisualDensity.compact,
          activeColor: TemaApp.azul,
        ),
        Expanded(child: Text(texto, style: TextStyle(fontSize: 11, color: context.colores.textoSecundario))),
      ],
    );
  }
}
