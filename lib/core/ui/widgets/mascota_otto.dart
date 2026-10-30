import 'package:flutter/material.dart';

/// Versión animada de Otto: flota suave (sube y baja lento).
class MascotaOttoAnimada extends StatefulWidget {
  final double tamano;
  final bool cara;
  const MascotaOttoAnimada({super.key, this.tamano = 24, this.cara = false});

  @override
  State<MascotaOttoAnimada> createState() => _MascotaOttoAnimadaState();
}

class _MascotaOttoAnimadaState extends State<MascotaOttoAnimada> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        // Movimiento suave de -4 a +4 px.
        final dy = -4 + (_ctrl.value * 8);
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: MascotaOtto(tamano: widget.tamano, cara: widget.cara),
    );
  }
}

/// Muestra la mascota "Otto" (un piche/mulita).
/// - Por defecto usa `assets/otto.png` (cuerpo entero).
/// - Con [cara] = true usa `assets/otto_cara.png` (versión de cara).
class MascotaOtto extends StatelessWidget {
  final double tamano;
  final bool cara;
  const MascotaOtto({super.key, this.tamano = 24, this.cara = false});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      cara ? 'assets/otto_cara.png' : 'assets/otto.png',
      width: tamano,
      height: tamano,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text('🦫', style: TextStyle(fontSize: tamano * 0.9)),
    );
  }
}
