import 'package:flutter/material.dart';

import '../../../core/tema/tema_app.dart';

/// Páginas del onboarding: bienvenida y listo.

class PaginaBienvenida extends StatelessWidget {
  final VoidCallback alSiguiente;
  const PaginaBienvenida({super.key, required this.alSiguiente});

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
class PaginaListo extends StatelessWidget {
  final String Function() obtenerNombre;
  final VoidCallback alFinalizar;

  const PaginaListo({super.key, required this.obtenerNombre, required this.alFinalizar});

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
