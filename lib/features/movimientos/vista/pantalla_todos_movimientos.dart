import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/ui/widgets/tarjeta_movimiento.dart';
import '../../../core/ui/widgets/categoria_ahorro.dart';
import '../logica/movimientos_provider.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../../panel_control/logica/metas_provider.dart';

class PantallaTodosMovimientos extends ConsumerStatefulWidget {
  const PantallaTodosMovimientos({super.key});

  @override
  ConsumerState<PantallaTodosMovimientos> createState() => _PantallaTodosMovimientosState();
}

class _PantallaTodosMovimientosState extends ConsumerState<PantallaTodosMovimientos> {
  final ScrollController _controladorScroll = ScrollController();
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _controladorScroll.addListener(_alHacerScroll);
  }

  @override
  void dispose() {
    _controladorScroll.removeListener(_alHacerScroll);
    _controladorScroll.dispose();
    super.dispose();
  }

  void _alHacerScroll() {
    if (_controladorScroll.position.pixels >= _controladorScroll.position.maxScrollExtent - 200) {
      ref.read(movimientosControladorProvider.notifier).cargarMas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final movimientos = ref.watch(movimientosFiltradosProvider);
    final categorias = ref.watch(categoriasControladorProvider).valueOrNull ?? [];
    final metas = (ref.watch(metasControladorProvider).valueOrNull ?? {}).keys;
    final filtroActivo = ref.watch(filtroMovimientosProvider);

    // Sobre lo ya filtrado por tipo, aplicamos la búsqueda por texto (concepto o
    // categoría) y ocultamos los movimientos sin categoría válida.
    final visibles = movimientos.where((mov) {
      if (!mov.esAhorro && !categorias.any((c) => c.id == mov.categoriaId)) return false;
      if (_busqueda.isEmpty) return true;
      final cat = categoriaDeMovimiento(mov, categorias, metas);
      return '${mov.descripcion ?? ''} ${cat.nombre}'.toLowerCase().contains(_busqueda);
    }).toList();

    return Scaffold(
      backgroundColor: context.colores.fondo,
      appBar: AppBar(
        title: Text('Todos los Movimientos', style: TextStyle(color: context.colores.textoPrimario)),
        backgroundColor: context.colores.fondo,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colores.textoPrimario),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _busqueda = v.trim().toLowerCase()),
                  style: TextStyle(color: context.colores.textoPrimario),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search, color: context.colores.textoSecundario, size: 20),
                    hintText: 'Buscar por concepto o categoría',
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chipFiltro(context, 'Todos', 'todos', filtroActivo),
                      _chipFiltro(context, 'Ingresos', 'ingreso', filtroActivo),
                      _chipFiltro(context, 'Gastos', 'gasto', filtroActivo),
                      _chipFiltro(context, 'Ahorros', 'ahorro', filtroActivo),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: visibles.isEmpty
                ? Center(
                    child: Text('No hay movimientos para mostrar.', style: TextStyle(color: context.colores.textoSecundario)),
                  )
                : ListView.builder(
                    controller: _controladorScroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: visibles.length + 1,
                    itemBuilder: (context, index) {
                      if (index == visibles.length) {
                        final controlador = ref.watch(movimientosControladorProvider.notifier);
                        return controlador.hayMasDatos
                            ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                            : const SizedBox(height: 24);
                      }
                      final mov = visibles[index];
                      final categoria = categoriaDeMovimiento(mov, categorias, metas);
                      return TarjetaMovimiento(
                        movimiento: mov,
                        categoria: categoria,
                        alEliminar: () {
                          if (mov.esAhorro) {
                            ref.read(metasControladorProvider.notifier).revertirAporte(mov);
                          } else {
                            ref.read(movimientosControladorProvider.notifier).eliminarMovimiento(mov.id!);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chipFiltro(BuildContext context, String texto, String valor, String activo) {
    final sel = activo == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        selected: sel,
        onSelected: (_) => ref.read(filtroMovimientosProvider.notifier).cambiarFiltro(valor),
        selectedColor: TemaApp.verde.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: sel ? TemaApp.verde : context.colores.textoSecundario,
          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
