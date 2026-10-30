import 'dart:ui';
import 'package:flutter/material.dart';
import '../../tema/tema_app.dart';

class FiltroPrivacidad extends StatefulWidget {
  final Widget child;

  const FiltroPrivacidad({super.key, required this.child});

  @override
  State<FiltroPrivacidad> createState() => _FiltroPrivacidadState();
}

class _FiltroPrivacidadState extends State<FiltroPrivacidad> with WidgetsBindingObserver {
  bool _ocultarPantalla = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      setState(() => _ocultarPantalla = true);
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _ocultarPantalla = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_ocultarPantalla)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
              child: Container(
                color: context.colores.fondo.withValues(alpha: 0.7),
                child: const Center(
                  child: Icon(Icons.lock_outline, size: 80, color: TemaApp.verde),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
