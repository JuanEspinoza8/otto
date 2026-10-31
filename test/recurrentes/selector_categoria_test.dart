import 'package:otto/features/categorias/logica/categorias_provider.dart';
import 'package:otto/features/categorias/modelo/categoria.dart';
import 'package:otto/features/recurrentes/modelo/plan.dart';
import 'package:otto/features/recurrentes/vista/dialogo_cuota.dart';
import 'package:otto/features/recurrentes/vista/dialogo_gasto_fijo.dart';
import 'package:otto/features/recurrentes/vista/selector_categoria_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Categoria _categoria(int id, String nombre, [String tipo = 'gasto']) =>
    Categoria(id: id, nombre: nombre, tipo: tipo, colorHex: '0xFF9E9E9E', icono: 'category');

class _Categorias extends CategoriasControlador {
  @override
  Future<List<Categoria>> build() async => [
        _categoria(1, 'Alimentación'),
        _categoria(7, 'Otros Gastos'),
        _categoria(9, 'Deudas'),
        _categoria(2, 'Sueldo', 'ingreso'),
      ];
}

Future<DropdownButton<int>> desplegable(WidgetTester tester, Widget contenido) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [categoriasControladorProvider.overrideWith(_Categorias.new)],
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: contenido))),
  ));
  await tester.pumpAndSettle();
  return tester.widget<DropdownButton<int>>(find.descendant(
    of: find.byType(SelectorCategoriaPlan),
    matching: find.byType(DropdownButton<int>),
  ));
}

List<String?> nombres(DropdownButton<int> boton) => [for (final i in boton.items!) (i.child as Text).data];

void main() {
  testWidgets('un gasto fijo nuevo muestra "Otros Gastos" una sola vez y elegida', (tester) async {
    final boton = await desplegable(tester, const DialogoGastoFijo());
    expect(nombres(boton), ['Alimentación', 'Otros Gastos', 'Deudas']);
    expect(boton.value, 7);
  });

  testWidgets('una cuota nueva va a "Deudas", como al confirmarla', (tester) async {
    final boton = await desplegable(tester, const DialogoCuota());
    expect(nombres(boton).where((n) => n == 'Otros Gastos'), hasLength(1));
    expect(boton.value, 9);
  });

  testWidgets('un plan con categoría propia la conserva', (tester) async {
    final boton = await desplegable(
      tester,
      SelectorCategoriaPlan(tipo: TipoPlan.fijo, categoriaId: 1, alCambiar: (_) {}),
    );
    expect(boton.value, 1);
  });
}
