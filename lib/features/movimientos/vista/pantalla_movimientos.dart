import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tema/tema_app.dart';
import '../../configuracion/logica/tema_provider.dart';
import 'formulario_movimiento.dart';

class PantallaMovimientos extends ConsumerStatefulWidget {
  const PantallaMovimientos({super.key});

  @override
  ConsumerState<PantallaMovimientos> createState() => _PantallaMovimientosState();
}

class _PantallaMovimientosState extends ConsumerState<PantallaMovimientos> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colores.fondo,
      appBar: AppBar(
        backgroundColor: context.colores.fondo,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Nuevo movimiento', style: TextStyle(color: context.colores.textoPrimario, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(temaControladorProvider) == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: context.colores.textoSecundario,
            ),
            onPressed: () => ref.read(temaControladorProvider.notifier).alternar(),
          ),
        ],
      ),
      body: const CustomScrollView(
        slivers: [
          // Sección del Formulario
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: FormularioMovimiento(),
            ),
          ),
        ],
      ),
    );
  }
}
