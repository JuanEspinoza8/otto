import 'package:otto/core/dinero/dinero.dart';
import 'package:otto/core/libro/modelo/meta.dart';
import 'package:otto/features/categorias/logica/presupuesto.dart';
import 'package:flutter_test/flutter_test.dart';

Dinero pesos(num p) => Dinero.desdeUnidades(p);

void main() {
  group('nivel del presupuesto', () {
    test('alerta desde el 80% y excedido recién al pasar el límite', () {
      expect(nivelPresupuesto(pesos(79999), pesos(100000)), NivelPresupuesto.normal);
      expect(nivelPresupuesto(pesos(80000), pesos(100000)), NivelPresupuesto.alerta);
      expect(nivelPresupuesto(pesos(100000), pesos(100000)), NivelPresupuesto.alerta);
      expect(nivelPresupuesto(pesos(116000), pesos(100000)), NivelPresupuesto.excedido);
      expect(nivelPresupuesto(pesos(116000), const Dinero.cero()), NivelPresupuesto.normal);
    });

    test('avisa solo al cruzar un umbral', () {
      expect(avisoPresupuesto('Salidas', pesos(20000), pesos(25000), pesos(30000)),
          'Llegaste al 83% del presupuesto de Salidas');
      expect(avisoPresupuesto('Salidas', pesos(25000), pesos(26000), pesos(30000)), isNull);
      expect(avisoPresupuesto('Salidas', pesos(26000), pesos(34800), pesos(30000)),
          r'Te pasaste del presupuesto de Salidas por $4.800');
    });
  });

  test('el progreso de una meta usa enteros', () {
    Meta meta(num saldo, num objetivo) => Meta(
          id: 1,
          cuentaId: 3,
          nombre: 'Viaje',
          icono: 'flight',
          objetivo: pesos(objetivo),
          saldo: pesos(saldo),
          fechaCreacion: DateTime(2026),
        );
    expect(meta(58000, 100000).porcentajeProgreso, 58);
    expect(meta(150000, 100000).porcentajeProgreso, 100);
    expect(meta(5000, 0).porcentajeProgreso, 0);
  });
}
