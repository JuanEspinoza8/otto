import 'package:otto/core/dinero/dinero.dart';
import 'package:otto/core/libro/consultas_libro.dart';
import 'package:otto/core/libro/libro_providers.dart';
import 'package:otto/features/panel_control/logica/dashboard_provider.dart';
import 'package:otto/features/panel_control/logica/dolar_blue_provider.dart';
import 'package:otto/features/panel_control/logica/metas_provider.dart';
import 'package:otto/features/panel_control/vista/encabezado_dashboard.dart';
import 'package:otto/features/panel_control/vista/widget_resumen_tarjetas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Blue extends DolarBlue {
  @override
  Future<Cotizacion?> build() async => const Cotizacion(compra: 1230, venta: 1250);
}

Dinero pesos(num p) => Dinero.desdeUnidades(p);

void main() {
  group('frase del mes', () {
    test('sin movimientos', () {
      expect(fraseDelMes(const TotalesMes()), 'Todavía no cargaste movimientos este mes.');
    });

    test('gastó más de lo que entró', () {
      final t = TotalesMes(ingresos: pesos(100000), gastos: pesos(130000), cantidadIngresos: 1, cantidadGastos: 3);
      expect(fraseDelMes(t), r'Este mes gastaste $30.000 más de lo que entró.');
    });

    test('ahorra más del 20%', () {
      final t = TotalesMes(ingresos: pesos(100000), gastos: pesos(60000), cantidadIngresos: 1, cantidadGastos: 3);
      expect(fraseDelMes(t), '¡Vas muy bien! Te queda el 40% de lo que entró.');
    });

    test('el porcentaje no pierde un punto por la coma flotante', () {
      final t = TotalesMes(ingresos: pesos(100000), gastos: pesos(71000), cantidadIngresos: 1, cantidadGastos: 3);
      expect(fraseDelMes(t), '¡Vas muy bien! Te queda el 29% de lo que entró.');
    });
  });

  testWidgets('el disponible es en pesos y los dólares van aparte', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        disponibleProvider.overrideWith((ref) async => pesos(584499.50)),
        totalesMesProvider.overrideWith((ref) async =>
            TotalesMes(ingresos: pesos(865000), gastos: pesos(770000), cantidadIngresos: 2, cantidadGastos: 5)),
        progresoMetasProvider.overrideWithValue(const ProgresoMetas(
            cantidad: 0, porcentaje: 0, guardadoArs: Dinero.cero(), guardadoUsd: Dinero.cero(Moneda.usd))),
        patrimonioDolaresProvider.overrideWith((ref) async => const PatrimonioDolares(
            libres: Dinero(50000, Moneda.usd), enMetas: Dinero(30000, Moneda.usd))),
        dolarBlueProvider.overrideWith(_Blue.new),
      ],
      child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WidgetResumenTarjetas()))),
    ));
    await tester.pumpAndSettle();

    expect(find.text(r'$584K'), findsOneWidget);
    expect(find.text('US\$800'), findsOneWidget);
    expect(find.text(r'≈ $1M al blue'), findsOneWidget);

    // Tocar un monto cicla el formato hasta el exacto.
    await tester.tap(find.text(r'$584K'));
    await tester.pump();
    await tester.tap(find.text(r'$584m'));
    await tester.pump();
    expect(find.text(r'$584.499,50'), findsOneWidget);
  });
}
