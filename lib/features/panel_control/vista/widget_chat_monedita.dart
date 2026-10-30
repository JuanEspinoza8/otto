import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/ui/widgets/mascota_otto.dart';
import '../logica/monedita_provider.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../../categorias/modelo/categoria.dart';

/// Widget del chat inteligente "Decile a Otto".
/// Interpreta gastos/ingresos en lenguaje natural (uno o varios por frase).
class WidgetChatMonedita extends ConsumerStatefulWidget {
  const WidgetChatMonedita({super.key});

  @override
  ConsumerState<WidgetChatMonedita> createState() => _WidgetChatMoneditaState();
}

class _WidgetChatMoneditaState extends ConsumerState<WidgetChatMonedita> {
  final _controladorTexto = TextEditingController();

  @override
  void dispose() {
    _controladorTexto.dispose();
    super.dispose();
  }

  void _enviarMensaje() {
    final texto = _controladorTexto.text.trim();
    if (texto.isEmpty) return;
    ref.read(moneditaControladorProvider.notifier).procesarMensaje(texto);
    _controladorTexto.clear();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(moneditaControladorProvider);
    final categorias = ref.watch(categoriasControladorProvider).valueOrNull ?? [];

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
              const MascotaOtto(tamano: 64, cara: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text('DECILE A OTTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colores.textoSecundario, letterSpacing: 1.1)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: context.colores.superficieAlta, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Contale tus gastos', style: TextStyle(fontSize: 9, color: context.colores.textoSecundario)),
                    const SizedBox(width: 4),
                    const Text('💬', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Propuestas (una tarjeta por movimiento detectado)
          if (estado.estado == EstadoMonedita.sugerencia)
            ...estado.propuestas.map((p) => _TarjetaPropuesta(propuesta: p, categorias: categorias)),

          // Error
          if (estado.estado == EstadoMonedita.error)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: TemaApp.rojo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Text('😕', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(estado.mensajeError ?? 'No pude entender el mensaje', style: const TextStyle(fontSize: 12, color: TemaApp.rojo))),
                ],
              ),
            ),

          // Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controladorTexto,
                  onSubmitted: (_) => _enviarMensaje(),
                  style: TextStyle(color: context.colores.textoPrimario),
                  decoration: InputDecoration(
                    hintText: 'Ej: "pagué 50mil de luz y el super 12 lucas"',
                    hintMaxLines: 2,
                    hintStyle: TextStyle(fontSize: 12, color: context.colores.textoSecundario),
                    filled: true,
                    fillColor: context.colores.superficieAlta,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(color: TemaApp.verde, borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  icon: estado.estado == EstadoMonedita.procesando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: estado.estado == EstadoMonedita.procesando ? null : _enviarMensaje,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de una propuesta interpretada por Otto, con confirmación.
class _TarjetaPropuesta extends ConsumerStatefulWidget {
  final PropuestaOtto propuesta;
  final List<Categoria> categorias;
  const _TarjetaPropuesta({required this.propuesta, required this.categorias});

  @override
  ConsumerState<_TarjetaPropuesta> createState() => _TarjetaPropuestaState();
}

class _TarjetaPropuestaState extends ConsumerState<_TarjetaPropuesta> {
  late bool _actualizarFijo;
  int? _categoriaOverride;

  @override
  void initState() {
    super.initState();
    _actualizarFijo = widget.propuesta.difiereDelFijo; // por defecto on si difiere
  }

  String get _nombreCategoria {
    final id = _categoriaOverride ?? widget.propuesta.sugerencia.categoriaId;
    final match = widget.categorias.where((c) => c.id == id);
    return match.isNotEmpty ? match.first.nombre : (widget.propuesta.sugerencia.nombreCategoria ?? 'Otros');
  }

  void _confirmar() {
    ref.read(moneditaControladorProvider.notifier).confirmar(
          widget.propuesta,
          actualizarFijo: _actualizarFijo,
          categoriaIdOverride: _categoriaOverride,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Movimiento registrado', style: TextStyle(color: Colors.white)), backgroundColor: TemaApp.verde),
    );
  }

  void _cambiarCategoria() {
    final tipo = widget.propuesta.sugerencia.tipo;
    final candidatas = widget.categorias.where((c) => c.tipo == tipo).toList();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
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
              children: candidatas.map((c) => ActionChip(
                avatar: Icon(Icons.category, size: 16, color: Color(int.parse(c.colorHex))),
                label: Text(c.nombre),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _categoriaOverride = c.id);
                },
              )).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.propuesta;
    final s = p.sugerencia;
    final esGasto = s.tipo == 'gasto';
    final colorTipo = esGasto ? TemaApp.rojo : TemaApp.verde;
    final formato = NumberFormat('#,##0.##', 'es_AR');

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
                child: Text(esGasto ? 'Gasto' : 'Ingreso', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('\$${formato.format(s.monto)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.colores.textoPrimario)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(s.descripcion, style: TextStyle(color: context.colores.textoSecundario, fontSize: 12)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _cambiarCategoria,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text('Categoría: ', style: TextStyle(color: context.colores.textoSecundario, fontSize: 12)),
                Text(_nombreCategoria, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colores.textoPrimario)),
                const Text('· Tocá para cambiar', style: TextStyle(color: TemaApp.verde, fontSize: 10, fontStyle: FontStyle.italic)),
              ],
            ),
          ),

          // Conciliación con un gasto fijo
          if (p.fijo != null && p.difiereDelFijo) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: TemaApp.azul.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'El fijo "${p.fijo!.nombre}" figuraba \$${formato.format(p.fijo!.monto)}.'
                    '${p.yaAplicadoEsteMes ? ' Ya se descontó este mes: se corrige a \$${formato.format(s.monto)}.' : ''}',
                    style: const TextStyle(fontSize: 11, color: TemaApp.azul),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _actualizarFijo,
                        onChanged: (v) => setState(() => _actualizarFijo = v ?? false),
                        visualDensity: VisualDensity.compact,
                        activeColor: TemaApp.azul,
                      ),
                      Expanded(child: Text('Actualizar el fijo a \$${formato.format(s.monto)} (para los próximos meses)', style: TextStyle(fontSize: 11, color: context.colores.textoSecundario))),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (p.fijo != null && p.yaAplicadoEsteMes) ...[
            const SizedBox(height: 8),
            Text('Coincide con el fijo "${p.fijo!.nombre}", que ya se descontó este mes con el mismo monto.',
                style: const TextStyle(fontSize: 11, color: TemaApp.azul)),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _confirmar,
                  style: ElevatedButton.styleFrom(backgroundColor: TemaApp.verde, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('✓ Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(moneditaControladorProvider.notifier).cancelar(widget.propuesta),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: context.colores.borde), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Descartar', style: TextStyle(color: context.colores.textoSecundario)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
