import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../tema/tema_app.dart';
import '../../../features/configuracion/logica/ajustes_provider.dart';

/// Envuelve la app y exige autenticación biométrica cuando está activada.
///
/// - Anti-bucle: el propio prompt del SO manda la app a `inactive`/`paused`,
///   lo que antes re-disparaba la autenticación en cadena. Se evita con
///   [_estaAutenticando].
/// - Arranque en frío: se espera a que carguen los ajustes antes de decidir,
///   así la huella se pide también al abrir la app desde cero (no sólo al
///   volver de segundo plano).
class BloqueoBiometrico extends ConsumerStatefulWidget {
  final Widget child;

  const BloqueoBiometrico({super.key, required this.child});

  @override
  ConsumerState<BloqueoBiometrico> createState() => _BloqueoBiometricoState();
}

class _BloqueoBiometricoState extends ConsumerState<BloqueoBiometrico> with WidgetsBindingObserver {
  bool _autenticado = false;
  bool _estaAutenticando = false;
  bool _dispararInicial = false;

  final LocalAuthentication _auth = LocalAuthentication();

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

  bool get _biometriaActiva =>
      ref.read(ajustesControladorProvider).valueOrNull?.biometriaActiva ?? false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_estaAutenticando) return; // el prompt del SO provoca inactive/paused

    if (state == AppLifecycleState.paused) {
      if (_biometriaActiva && _autenticado) {
        setState(() => _autenticado = false);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_biometriaActiva && !_autenticado) {
        _autenticar();
      }
    }
  }

  Future<void> _autenticar() async {
    if (_estaAutenticando) return;
    if (!_biometriaActiva) {
      if (!_autenticado) setState(() => _autenticado = true);
      return;
    }

    _estaAutenticando = true;
    try {
      final autenticado = await _auth.authenticate(
        localizedReason: 'Usá tu huella para entrar a Otto',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );
      if (mounted && autenticado) setState(() => _autenticado = true);
    } catch (e) {
      debugPrint('Error de biometría: $e');
      if (mounted) setState(() => _autenticado = true); // no dejar al usuario afuera
    } finally {
      _estaAutenticando = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ajustesAsync = ref.watch(ajustesControladorProvider);

    // Mientras no sepamos si la biometría está activa, mostramos una pantalla
    // neutra (no dejamos ver la app antes de decidir).
    if (!ajustesAsync.hasValue) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(color: TemaApp.verde)),
      );
    }

    final biometria = ajustesAsync.valueOrNull?.biometriaActiva ?? false;
    if (!biometria || _autenticado) return widget.child;

    // Primera vez que llegamos acá con biometría activa: pedimos la huella.
    if (!_estaAutenticando && !_dispararInicial) {
      _dispararInicial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _autenticar());
    }

    return Scaffold(
      backgroundColor: context.colores.fondo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fingerprint, size: 100, color: TemaApp.verde),
            const SizedBox(height: 24),
            Text('Otto Bloqueado', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.colores.textoPrimario)),
            const SizedBox(height: 8),
            Text('Tu privacidad está protegida', style: TextStyle(color: context.colores.textoSecundario)),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: TemaApp.verde, foregroundColor: Colors.white),
              onPressed: _estaAutenticando ? null : _autenticar,
              child: const Text('Desbloquear'),
            ),
          ],
        ),
      ),
    );
  }
}
