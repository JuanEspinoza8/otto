import 'package:otto/core/tema/tema_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Brightness?> iconosDeLaBarra(WidgetTester tester, Brightness brillo, Widget pantalla) async {
  await tester.pumpWidget(MaterialApp(
    theme: TemaApp.obtenerTema(brillo),
    builder: (context, child) => BarraDeEstadoDelTema(child: child!),
    home: pantalla,
  ));
  await tester.pump();
  return SystemChrome.latestStyle?.statusBarIconBrightness;
}

void main() {
  testWidgets('tema claro con AppBar transparente (Inicio): íconos oscuros', (tester) async {
    final pantalla = Scaffold(appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Hola')));
    expect(await iconosDeLaBarra(tester, Brightness.light, pantalla), Brightness.dark);
  });

  testWidgets('tema claro sin AppBar (Categorías): íconos oscuros', (tester) async {
    const pantalla = Scaffold(body: SafeArea(child: Text('Mis Categorías')));
    expect(await iconosDeLaBarra(tester, Brightness.light, pantalla), Brightness.dark);
  });

  testWidgets('tema oscuro: íconos claros', (tester) async {
    const pantalla = Scaffold(body: SafeArea(child: Text('Mis Categorías')));
    expect(await iconosDeLaBarra(tester, Brightness.dark, pantalla), Brightness.light);
    final conAppBar = Scaffold(appBar: AppBar(backgroundColor: Colors.transparent));
    expect(await iconosDeLaBarra(tester, Brightness.dark, conAppBar), Brightness.light);
  });
}
