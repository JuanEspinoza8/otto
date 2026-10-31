import 'package:otto/core/dinero/dinero.dart';
import 'package:otto/core/seguridad/autenticador.dart';
import 'package:otto/core/seguridad/proteccion_app.dart';
import 'package:otto/features/configuracion/logica/ajustes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _AutenticadorFalso implements Autenticador {
  bool respuesta = false;
  int pedidos = 0;
  bool? pantallaProtegida;

  @override
  Future<bool> disponible() async => true;

  @override
  Future<bool> autenticar(String motivo) async {
    pedidos++;
    return respuesta;
  }

  @override
  Future<void> protegerPantalla(bool activar) async => pantallaProtegida = activar;
}

class _AjustesFijos extends AjustesControlador {
  _AjustesFijos(this.biometria);
  final bool biometria;

  @override
  Future<Ajustes> build() async => Ajustes(
        biometriaActiva: biometria,
        recordatorioDiario: false,
        horariosRecordatorios: const [],
        nombreUsuario: '',
        salarioMensual: const Dinero.cero(),
        valorHoraExtra: const Dinero.cero(),
        iaActiva: false,
        bannerRecordatorioOculto: true,
      );
}

Widget _app(_AutenticadorFalso auth, {required bool biometria}) => ProviderScope(
      overrides: [
        autenticadorProvider.overrideWithValue(auth),
        ajustesControladorProvider.overrideWith(() => _AjustesFijos(biometria)),
      ],
      child: MaterialApp(
        builder: (context, child) => ProteccionApp(child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(content: Text('Saldo secreto')),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('sin bloqueo activado no pide nada', (tester) async {
    final auth = _AutenticadorFalso();
    await tester.pumpWidget(_app(auth, biometria: false));
    await tester.pumpAndSettle();

    expect(auth.pedidos, 0);
    expect(find.text('Otto está bloqueado'), findsNothing);
    expect(auth.pantallaProtegida, isFalse);
  });

  testWidgets('si la autenticación falla, la app sigue bloqueada', (tester) async {
    final auth = _AutenticadorFalso();
    await tester.pumpWidget(_app(auth, biometria: true));
    await tester.pumpAndSettle();

    expect(auth.pedidos, 1);
    expect(find.text('Otto está bloqueado'), findsOneWidget);
    expect(find.text('No se pudo verificar. Probá de nuevo.'), findsOneWidget);
    expect(auth.pantallaProtegida, isTrue);

    // Lo de abajo no responde mientras está bloqueada.
    await tester.tap(find.text('Abrir'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Saldo secreto'), findsNothing);

    auth.respuesta = true;
    await tester.tap(find.text('Desbloquear'));
    await tester.pumpAndSettle();
    expect(find.text('Otto está bloqueado'), findsNothing);
  });

  testWidgets('al volver a la app, tapa también un diálogo abierto', (tester) async {
    final auth = _AutenticadorFalso()..respuesta = true;
    await tester.pumpWidget(_app(auth, biometria: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Saldo secreto'), findsOneWidget);

    auth.respuesta = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Otto está bloqueado'), findsOneWidget);
    // El diálogo sigue en el árbol (no se pierde lo abierto) pero tapado.
    expect(find.text('Saldo secreto'), findsOneWidget);
    expect(find.text('Saldo secreto').hitTestable(), findsNothing);
  });
}
