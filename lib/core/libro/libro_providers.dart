import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

import '../base_de_datos/gestor_base_datos.dart';
import '../dinero/dinero.dart';
import 'consultas_libro.dart';
import 'modelo/cuenta.dart';
import 'servicio_libro.dart';

part 'libro_providers.g.dart';

/// La base abierta. En los tests se reemplaza por una en memoria.
@Riverpod(keepAlive: true)
Future<Database> baseDatos(Ref ref) => GestorBaseDatos.instancia.obtenerBaseDatos();

/// Contador que sube con cada escritura en la base. Todas las lecturas lo
/// observan, así se recalculan después de guardar (y no al paginar listas).
@Riverpod(keepAlive: true)
class VersionDatos extends _$VersionDatos {
  @override
  int build() => 0;

  void cambiaron() => state++;
}

/// Corre [accion] en una transacción y avisa que cambiaron los datos.
Future<T> escribirEnTransaccion<T>(Ref ref, Future<T> Function(Transaction txn) accion) async {
  final db = await ref.read(baseDatosProvider.future);
  final resultado = await db.transaction(accion);
  ref.read(versionDatosProvider.notifier).cambiaron();
  return resultado;
}

/// Corre [accion] en una transacción del libro y avisa que cambiaron los datos.
Future<T> escribirEnLibro<T>(Ref ref, Future<T> Function(ServicioLibro libro) accion) =>
    escribirEnTransaccion(ref, (txn) => accion(ServicioLibro(txn)));

/// Consultas sobre la base actual, recalculadas cuando cambian los datos.
Future<ConsultasLibro> consultasLibro(Ref ref) async {
  ref.watch(versionDatosProvider);
  return ConsultasLibro(await ref.watch(baseDatosProvider.future));
}

/// La plata libre en pesos (saldo de "Libre ARS"). No depende del dólar.
@riverpod
Future<Dinero> disponible(Ref ref) async => (await consultasLibro(ref)).disponible();

@riverpod
Future<Map<int, Dinero>> saldos(Ref ref) async => (await consultasLibro(ref)).saldos();

@riverpod
Future<List<Cuenta>> cuentas(Ref ref) async => (await consultasLibro(ref)).cuentas();
