import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/ui/widgets/mascota_otto.dart';
import '../logica/onboarding_provider.dart';
import '../../../core/dinero/dinero.dart';
import '../../../core/dinero/formateador_monto.dart';

/// Pantalla de onboarding que se muestra al primer uso de la app.
/// Flujo de 3 pasos: Bienvenida → Datos personales → Listo.
class PantallaOnboarding extends ConsumerStatefulWidget {
  final VoidCallback alFinalizar;
  const PantallaOnboarding({super.key, required this.alFinalizar});

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

    widget.alFinalizar();
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
                  _PaginaBienvenida(alSiguiente: _siguiente),
                  _PaginaDatos(
                    controladorNombre: _controladorNombre,
                    controladorSalario: _controladorSalario,
                    controladorHoraExtra: _controladorHoraExtra,
                    alSiguiente: _siguiente,
                  ),
                  _PaginaListo(
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
class _PaginaBienvenida extends StatelessWidget {
  final VoidCallback alSiguiente;
  const _PaginaBienvenida({required this.alSiguiente});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Logo animado
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: TemaApp.verde.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5),
              ],
            ),
            child: const Center(
              child: Text('💰', style: TextStyle(fontSize: 60)),
            ),
          ),
          const SizedBox(height: 40),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.green, Color(0xFF81C784)],
            ).createShader(bounds),
            child: const Text(
              'Otto',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tu gestor financiero personal',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '100% privado · 100% local · 0% estrés',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: alSiguiente,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Empezar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Página 2: Datos personales
class _PaginaDatos extends StatelessWidget {
  final TextEditingController controladorNombre;
  final TextEditingController controladorSalario;
  final TextEditingController controladorHoraExtra;
  final VoidCallback alSiguiente;

  const _PaginaDatos({
    required this.controladorNombre,
    required this.controladorSalario,
    required this.controladorHoraExtra,
    required this.alSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          const SizedBox(height: 24),
          const Center(child: MascotaOtto(cara: true, tamano: 132)),
          const SizedBox(height: 16),
          const Text(
            '¿Cómo te llamás?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Otto quiere conocerte para darte consejos personalizados.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controladorNombre,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Tu nombre',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.grey[900],
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '¿Cuánto ganás por mes? (aproximado)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esto nos ayuda a calcular tus porcentajes de ahorro. Podés cambiarlo después.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controladorSalario,
            keyboardType: TextInputType.number,
            inputFormatters: [FormateadorMonto()],
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.grey[900],
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '¿Cuánto te pagan la hora extra? (opcional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Si hacés horas extra, Otto calcula el total con sólo ingresar las horas.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controladorHoraExtra,
            keyboardType: TextInputType.number,
            inputFormatters: [FormateadorMonto()],
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
              hintText: '0 por hora',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.grey[900],
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
            ),
          ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: alSiguiente,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Siguiente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Página 3: Confirmación final
class _PaginaListo extends StatelessWidget {
  final String Function() obtenerNombre;
  final VoidCallback alFinalizar;

  const _PaginaListo({required this.obtenerNombre, required this.alFinalizar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Text('🎉', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          const Text(
            '¡Todo listo!',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Bienvenido a Otto.\nOtto te va a ayudar a controlar tu plata.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                _InfoItem(icono: Icons.lock_outline, texto: 'Tus datos nunca salen del celular'),
                SizedBox(height: 12),
                _InfoItem(icono: Icons.chat_bubble_outline, texto: 'Dictale gastos a Otto'),
                SizedBox(height: 12),
                _InfoItem(icono: Icons.savings_outlined, texto: 'Creá metas y ahorrá'),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: alFinalizar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('¡Empezar a usar Otto!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _InfoItem({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: Colors.green, size: 20),
        const SizedBox(width: 12),
        Text(texto, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }
}
