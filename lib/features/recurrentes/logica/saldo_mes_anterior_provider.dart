import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/libro/consultas_libro.dart';
import '../../../core/libro/libro_providers.dart';
import '../../../core/libro/modelo/meta.dart';
import '../../../core/libro/servicio_libro.dart';
import '../../../core/utilidades/fechas.dart';
import '../../panel_control/logica/dolar_blue_provider.dart';
import '../repositorio/avisos_repositorio.dart';

part 'saldo_mes_anterior_provider.g.dart';

/// El "sobrante" del mes anterior: lo que quedó libre ese mes, ofrecido para
/// guardarlo en una meta. Nunca se ofrece más que el disponible de hoy.
@riverpod
class SaldoMesAnterior extends _$SaldoMesAnterior {
  @override
  Future<Dinero> build() async {
    final consultas = await consultasLibro(ref);
    final db = await ref.watch(baseDatosProvider.future);
    final actual = Periodo.de(DateTime.now());
    if (await AvisosRepositorio(db).resuelto(AvisosRepositorio.saldoAnterior, actual)) {
      return const Dinero.cero();
    }
    final sobrante = (await consultas.sobranteDelMes(actual.anterior)).min(await consultas.disponible());
    return sobrante.esPositivo ? sobrante : const Dinero.cero();
  }

  /// Aporta [pesos] a la meta con fecha del último día del mes anterior (así
  /// cuenta en ese mes y no vuelve a restarse en este) y cierra el aviso, todo
  /// en la misma transacción: si el aporte falla, el aviso sigue abierto.
  Future<void> aportarAMeta(Meta meta, Dinero pesos) {
    final actual = Periodo.de(DateTime.now());
    final ultimoDiaAnterior = actual.primerDia.subtract(const Duration(days: 1));
    final cotizacion = ref.read(dolarBlueProvider).valueOrNull?.venta;
    return escribirEnTransaccion(ref, (txn) async {
      final sobrante = await ConsultasLibro(txn).sobranteDelMes(actual.anterior);
      if (pesos > sobrante) throw ErrorLibro('El sobrante es ${sobrante.formatear()}');
      await ServicioLibro(txn).aportarAMeta(meta.id, pesos, cotizacion: cotizacion, fecha: ultimoDiaAnterior);
      await AvisosRepositorio(txn).marcar(AvisosRepositorio.saldoAnterior, actual);
    });
  }

  /// El usuario decide dejar el sobrante en el disponible.
  Future<void> descartar() => escribirEnTransaccion(
      ref, (txn) => AvisosRepositorio(txn).marcar(AvisosRepositorio.saldoAnterior, Periodo.de(DateTime.now())));
}
