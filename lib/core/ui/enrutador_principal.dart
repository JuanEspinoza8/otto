import 'package:flutter/material.dart';
import '../tema/tema_app.dart';
import '../../features/movimientos/vista/pantalla_movimientos.dart';
import '../../features/panel_control/vista/pantalla_dashboard.dart';
import '../../features/configuracion/vista/pantalla_configuracion.dart';
import '../../features/recurrentes/vista/pantalla_fijos.dart';
import '../../features/recurrentes/vista/pantalla_cuotas.dart';

class EnrutadorPrincipal extends StatefulWidget {
  const EnrutadorPrincipal({super.key});

  @override
  State<EnrutadorPrincipal> createState() => _EnrutadorPrincipalState();
}

class _EnrutadorPrincipalState extends State<EnrutadorPrincipal> {
  int _indiceActual = 0; // arranca en Inicio
  late final PageController _controladorPagina;

  @override
  void initState() {
    super.initState();
    _controladorPagina = PageController(initialPage: _indiceActual);
  }

  @override
  void dispose() {
    _controladorPagina.dispose();
    super.dispose();
  }

  void _alCambiarPagina(int indice) {
    setState(() {
      _indiceActual = indice;
    });
  }

  void _alTocarItemNav(int indice) {
    _controladorPagina.animateToPage(
      indice,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controladorPagina,
        onPageChanged: _alCambiarPagina,
        children: const [
          // 0: Inicio
          PantallaDashboard(),
          // 1: Registrar
          PantallaMovimientos(),
          // 2: Fijos
          PantallaFijos(),
          // 3: Cuotas
          PantallaCuotas(),
          // 4: Menú
          PantallaConfiguracion(),
        ],
      ),
      bottomNavigationBar: Theme(
        // Sobrescribimos el splashColor y highlightColor para que no haga efecto onda
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: context.colores.superficie,
          selectedItemColor: TemaApp.verde, // Verde Otto
          unselectedItemColor: context.colores.textoSecundario,
          currentIndex: _indiceActual,
          onTap: _alTocarItemNav,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Registrar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.format_list_bulleted),
              label: 'Fijos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card_outlined),
              activeIcon: Icon(Icons.credit_card),
              label: 'Cuotas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Menú',
            ),
          ],
        ),
      ),
    );
  }
}
