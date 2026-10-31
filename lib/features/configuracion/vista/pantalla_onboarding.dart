import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logica/onboarding_provider.dart';
import 'pagina_datos_onboarding.dart';
import 'paginas_onboarding.dart';
import '../../../core/dinero/dinero.dart';

/// Pantalla de onboarding que se muestra al primer uso de la app.
/// Flujo de 3 pasos: Bienvenida → Datos personales → Listo.
class PantallaOnboarding extends ConsumerStatefulWidget {
  const PantallaOnboarding({super.key});

  @override
  ConsumerState<PantallaOnboarding> createState() => _PantallaOnboardingState();
}

class _PantallaOnboardingState extends ConsumerState<PantallaOnboarding> {
  final _controladorPagina = PageController();
  final _controladorNombre = TextEditingController();
  final _controladorSalario = TextEditingController();
  final _controladorHoraExtra = TextEditingController();
  int _paginaActual = 0;

  @override
  void dispose() {
    _controladorPagina.dispose();
    _controladorNombre.dispose();
    _controladorSalario.dispose();
    _controladorHoraExtra.dispose();
    super.dispose();
  }

  void _siguiente() {
    if (_paginaActual < 2) {
      _controladorPagina.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finalizar() async {
    final nombre = _controladorNombre.text.trim();
    final salario = Dinero.parsear(_controladorSalario.text) ?? const Dinero.cero();
    final horaExtra = Dinero.parsear(_controladorHoraExtra.text) ?? const Dinero.cero();

    await ref.read(onboardingControladorProvider.notifier).completarOnboarding(
      nombre: nombre.isNotEmpty ? nombre : 'Usuario',
      salarioMensual: salario,
      valorHoraExtra: horaExtra,
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de progreso
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: i <= _paginaActual ? Colors.green : Colors.grey[800],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Páginas
            Expanded(
              child: PageView(
                controller: _controladorPagina,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _paginaActual = i),
                children: [
                  PaginaBienvenida(alSiguiente: _siguiente),
                  PaginaDatos(
                    controladorNombre: _controladorNombre,
                    controladorSalario: _controladorSalario,
                    controladorHoraExtra: _controladorHoraExtra,
                    alSiguiente: _siguiente,
                  ),
                  PaginaListo(
                    obtenerNombre: () => _controladorNombre.text.trim(),
                    alFinalizar: _finalizar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Página 1: Bienvenida
