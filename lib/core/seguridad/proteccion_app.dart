import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/configuracion/logica/ajustes_provider.dart';
import '../tema/tema_app.dart';
import 'autenticador.dart';

/// Bloqueo biométrico y desenfoque de privacidad para toda la app.
///
/// Va en `MaterialApp.builder`, así queda por encima del Navigator: tapa
/// también las pantallas abiertas con `Navigator.push` y los diálogos. La app
/// sigue en el árbol debajo del bloqueo, de modo que no se pierde lo que
/// estaba a medio cargar.
class ProteccionApp extends ConsumerStatefulWidget {
  const ProteccionApp({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ProteccionApp> createState() => _ProteccionAppState();
}

class _ProteccionAppState extends ConsumerState<ProteccionApp> with WidgetsBindingObserver {
  bool _decidido = false;
  bool _bloqueada = false;
  bool _oculta = false;
  bool _autenticando = false;
  bool _fallo = false;

  bool get _activa => ref.read(ajustesControladorProvider).valueOrNull?.biometriaActiva ?? false;

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
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    // El diálogo del sistema que pide la huella también pausa la app.
    if (_autenticando) return;
    switch (estado) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        setState(() => _oculta = true);
      case AppLifecycleState.paused:
        setState(() {
          _oculta = true;
          if (_activa) _bloquear();
        });
      case AppLifecycleState.resumed:
        setState(() => _oculta = false);
        if (_bloqueada && _activa) _autenticar();
      case AppLifecycleState.detached:
        break;
    }
  }

  void _bloquear() {
    _bloqueada = true;
    // Sin foco, el teclado no puede escribir en un campo tapado por el bloqueo.
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _autenticar() async {
    if (_autenticando) return;
    setState(() {
      _autenticando = true;
      _fallo = false;
    });
    final ok = await ref.read(autenticadorProvider).autenticar('Desbloqueá Otto');
    if (!mounted) return;
    setState(() {
      _autenticando = false;
      // Si falla o hay un error, la app sigue bloqueada.
      _bloqueada = !ok;
      _fallo = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ajustes = ref.watch(ajustesControladorProvider);
    ref.listen(ajustesControladorProvider.select((a) => a.valueOrNull?.biometriaActiva), (_, activa) {
      ref.read(autenticadorProvider).protegerPantalla(activa ?? false);
    });

    if (!_decidido && ajustes.hasValue) {
      _decidido = true;
      final activa = ajustes.requireValue.biometriaActiva;
      ref.read(autenticadorProvider).protegerPantalla(activa);
      if (activa) {
        _bloquear();
        WidgetsBinding.instance.addPostFrameCallback((_) => _autenticar());
      }
    }

    final activa = ajustes.valueOrNull?.biometriaActiva ?? false;
    final esperando = !_decidido;
    final tapada = esperando || (activa && _bloqueada);

    return Stack(
      children: [
        ExcludeSemantics(
          excluding: tapada,
          child: AbsorbPointer(absorbing: tapada, child: widget.child),
        ),
        if (_oculta && !tapada) const Positioned.fill(child: _Desenfoque()),
        if (tapada)
          Positioned.fill(
            child: esperando
                ? const ColoredBox(color: Color(0xFF0A0A0A))
                : _PantallaBloqueo(
                    autenticando: _autenticando,
                    fallo: _fallo,
                    alDesbloquear: _autenticar,
                  ),
          ),
      ],
    );
  }
}

class _Desenfoque extends StatelessWidget {
  const _Desenfoque();

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: ColoredBox(
        color: context.colores.fondo.withValues(alpha: 0.7),
        child: const Center(child: Icon(Icons.lock_outline, size: 80, color: TemaApp.verde)),
      ),
    );
  }
}

class _PantallaBloqueo extends StatelessWidget {
  const _PantallaBloqueo({required this.autenticando, required this.fallo, required this.alDesbloquear});

  final bool autenticando;
  final bool fallo;
  final VoidCallback alDesbloquear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colores.fondo,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fingerprint, size: 100, color: TemaApp.verde),
              const SizedBox(height: 24),
              Text('Otto está bloqueado',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.colores.textoPrimario)),
              const SizedBox(height: 8),
              Text(
                fallo ? 'No se pudo verificar. Probá de nuevo.' : 'Tu privacidad está protegida',
                style: TextStyle(color: fallo ? TemaApp.rojo : context.colores.textoSecundario),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: TemaApp.verde, foregroundColor: Colors.white),
                onPressed: autenticando ? null : alDesbloquear,
                child: const Text('Desbloquear'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
