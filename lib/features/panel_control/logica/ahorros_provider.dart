import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/base_de_datos/esquema.dart';
import '../../../core/dinero/dinero.dart';
import '../../../core/libro/libro_providers.dart';

part 'ahorros_provider.g.dart';

/// Plata que el usuario ya tenía antes de usar la app.
class AhorroPrevio {
  const AhorroPrevio({required this.ars, required this.usd});
  final Dinero ars;
  final Dinero usd;
}

/// Ahorro previo: el saldo inicial de "Libre ARS" y de "Dólares".
@riverpod
class AhorroPrevioControlador extends _$AhorroPrevioControlador {
  @override
  Future<AhorroPrevio> build() async {
    final consultas = await consultasLibro(ref);
    return AhorroPrevio(
      ars: await consultas.saldoInicial(Esquema.cuentaLibreArs, Moneda.ars),
      usd: await consultas.saldoInicial(Esquema.cuentaDolares, Moneda.usd),
    );
  }

  Future<void> fijarArs(Dinero monto) => escribirEnLibro(
      ref, (l) => l.fijarSaldoInicial(Esquema.cuentaLibreArs, monto, fecha: DateTime.now()));

  Future<void> fijarUsd(Dinero monto) => escribirEnLibro(
      ref, (l) => l.fijarSaldoInicial(Esquema.cuentaDolares, monto, fecha: DateTime.now()));
}
