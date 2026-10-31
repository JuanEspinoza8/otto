import 'package:otto/core/dinero/dinero.dart';
import 'package:otto/core/dinero/formateador_monto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

int? centavos(String texto) => Dinero.parsear(texto)?.centavos;

void main() {
  group('Dinero.parsear', () {
    test('formato es_AR con miles y decimales', () {
      expect(centavos('1.234,56'), 123456);
      expect(centavos('150.000'), 15000000);
      expect(centavos('1.500.000'), 150000000);
      expect(centavos(r'$ 25.000'), 2500000);
      expect(centavos('1,5'), 150);
    });

    test('un punto seguido de 1 o 2 dígitos es decimal', () {
      expect(centavos('1500.50'), 150050);
      expect(centavos('1500.5'), 150050);
      expect(centavos('1.5'), 150);
    });

    test('sufijos coloquiales', () {
      expect(centavos('1.5 lucas'), 150000);
      expect(centavos('25 mil'), 2500000);
      expect(centavos('25k'), 2500000);
      expect(centavos('1 luca'), 100000);
      expect(centavos('2 palos'), 200000000);
    });

    test('hasta 15 dígitos enteros', () {
      expect(centavos('999999999999999'), 99999999999999900);
      expect(centavos('999.999.999.999.999,99'), 99999999999999999);
      expect(centavos('1000000000000000'), isNull);
    });

    test('rechaza negativos, vacíos y basura', () {
      expect(centavos('-1.500'), isNull);
      expect(centavos(''), isNull);
      expect(centavos('   '), isNull);
      expect(centavos('.'), isNull);
      expect(centavos('abc'), isNull);
      expect(centavos('1,234,5'), isNull);
      expect(centavos('12.34.5'), isNull);
      expect(centavos('1,555'), isNull);
    });

    test('dólares', () {
      final d = Dinero.parsear('US\$ 300', moneda: Moneda.usd)!;
      expect(d, const Dinero(30000, Moneda.usd));
    });
  });

  group('Dinero.formatear', () {
    test('muestra decimales solo si los hay', () {
      expect(const Dinero(123456).formatear(), r'$1.234,56');
      expect(const Dinero(123400).formatear(), r'$1.234');
      expect(const Dinero(150).formatear(), r'$1,50');
      expect(const Dinero(-5000000).formatear(), r'-$50.000');
      expect(const Dinero(30000, Moneda.usd).formatear(), r'US$300');
      expect(const Dinero(123456).formatear(simbolo: false), '1.234,56');
    });

    test('abreviado', () {
      expect(const Dinero(85000000).formatear(abreviado: true), r'$850K');
      expect(const Dinero(150000000).formatear(abreviado: true), r'$1,5M');
      expect(const Dinero(99900).formatear(abreviado: true), r'$999');
    });

    test('ida y vuelta', () {
      for (final c in [1, 99, 100, 123456, 99999999999999999]) {
        final d = Dinero(c);
        expect(Dinero.parsear(d.formatear()), d);
      }
    });
  });

  group('operaciones', () {
    test('suma y compara en la misma moneda', () {
      expect(const Dinero(100) + const Dinero(250), const Dinero(350));
      expect(const Dinero(100) < const Dinero(250), isTrue);
    });

    test('no mezcla monedas', () {
      expect(() => const Dinero(100) + const Dinero(100, Moneda.usd), throwsArgumentError);
    });

    test('convierte con la cotización', () {
      expect(const Dinero(10000000).convertir(Moneda.usd, 1000), const Dinero(10000, Moneda.usd));
      expect(const Dinero(10000, Moneda.usd).convertir(Moneda.ars, 1250), const Dinero(12500000));
    });

    test('multiplica redondeando al centavo', () {
      expect(const Dinero(500000).por(1.5), const Dinero(750000));
    });
  });

  group('FormateadorMonto', () {
    TextEditingValue escribir(String anterior, String nuevo) => FormateadorMonto().formatEditUpdate(
          TextEditingValue(text: anterior, selection: TextSelection.collapsed(offset: anterior.length)),
          TextEditingValue(text: nuevo, selection: TextSelection.collapsed(offset: nuevo.length)),
        );

    test('agrupa miles', () {
      expect(escribir('150.00', '150.000').text, '150.000');
      expect(escribir('1.500', '1.5000').text, '15.000');
    });

    test('un punto tecleado es la coma decimal', () {
      expect(escribir('1.500', '1.500.').text, '1.500,');
      expect(escribir('1.500,', '1.500,5').text, '1.500,5');
    });

    test('un monto pegado con punto decimal', () {
      expect(escribir('', '1500.50').text, '1.500,50');
    });

    test('corta a 2 decimales', () {
      expect(escribir('1,23', '1,234').text, '1,23');
    });
  });
}
