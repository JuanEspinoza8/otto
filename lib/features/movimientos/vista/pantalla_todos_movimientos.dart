import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/libro/consultas_libro.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/utilidades/texto.dart';
import '../logica/mes_seleccionado_provider.dart';
import '../logica/movimientos_provider.dart';
import 'fila_movimiento.dart';

class PantallaTodosMovimientos extends ConsumerStatefulWidget {
  const PantallaTodosMovimientos({super.key});

  @override
  ConsumerState<PantallaTodosMovimientos> createState() => _PantallaTodosMovimientosState();
}

class _PantallaTodosMovimientosState extends ConsumerState<PantallaTodosMovimientos> {
  final ScrollController _controladorScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _controladorScroll.addListener(_alHacerScroll);
  }

  @override
  void dispose() {
    _controladorScroll.dispose();
    super.dispose();
  }

  void _alHacerScroll() {
    if (_controladorScroll.position.pixels >= _controladorScroll.position.maxScrollExtent - 200) {
      ref.read(movimientosBuscadosProvider.notifier).cargarMas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final movimientosAsync = ref.watch(movimientosBuscadosProvider);
    final hayMas = ref.watch(movimientosBuscadosProvider.notifier).hayMasDatos;
    final filtroActivo = ref.watch(criteriosBusquedaProvider).filtro;
    final mes = ref.watch(mesSeleccionadoProvider);
    final movimientos = movimientosAsync.valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: context.colores.fondo,
      appBar: AppBar(
        title: Text('Movimientos de ${DateFormat('MMMM', 'es').format(mes)}',
            style: TextStyle(color: context.colores.textoPrimario)),
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
                  onChanged: (v) => ref.read(criteriosBusquedaProvider.notifier).buscar(v),
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
                      for (final filtro in FiltroMovimientos.values) _chipFiltro(context, filtro, filtroActivo),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: movimientosAsync.isLoading && movimientos.isEmpty
                ? const Center(child: CircularProgressIndicator(color: TemaApp.verde))
                : movimientos.isEmpty
                    ? Center(
                        child: Text('No hay movimientos para mostrar.',
                            style: TextStyle(color: context.colores.textoSecundario)),
                      )
                    : ListView.builder(
                        controller: _controladorScroll,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: movimientos.length + 1,
                        itemBuilder: (context, index) {
                          if (index == movimientos.length) {
                            return hayMas
                                ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                                : const SizedBox(height: 24);
                          }
                          final mov = movimientos[index];
                          return FilaMovimiento(key: ValueKey(mov.id), movimiento: mov);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chipFiltro(BuildContext context, FiltroMovimientos filtro, FiltroMovimientos activo) {
    final sel = activo == filtro;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(capitalizar(filtro.name)),
        selected: sel,
        onSelected: (_) => ref.read(criteriosBusquedaProvider.notifier).filtrar(filtro),
        selectedColor: TemaApp.verde.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: sel ? TemaApp.verde : context.colores.textoSecundario,
          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
