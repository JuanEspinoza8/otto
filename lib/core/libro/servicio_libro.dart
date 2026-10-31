import 'package:sqflite/sqflite.dart';

import '../base_de_datos/esquema.dart';
import '../dinero/dinero.dart';
import '../utilidades/fechas.dart';
import 'modelo/cuenta.dart';
import 'modelo/movimiento.dart';

/// Una operación no se puede hacer. El mensaje se muestra tal cual al usuario.
class ErrorLibro implements Exception {
  const ErrorLibro(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Único camino de escritura del libro.
///
/// Recibe un [DatabaseExecutor]: puede ser la base o una transacción, así las
/// operaciones se pueden componer (por ejemplo, confirmar un plan escribe el
/// gasto y la aplicación juntos). Las validaciones de saldo se hacen dentro de
/// la misma transacción que la escritura; usá [ServicioLibro.transaccion].
class ServicioLibro {
  ServicioLibro(this._db);

  final DatabaseExecutor _db;

  static Future<T> transaccion<T>(Database db, Future<T> Function(ServicioLibro libro) accion) =>
      db.transaction((txn) => accion(ServicioLibro(txn)));

  // ---------------------------------------------------------------------------
  // Lecturas que necesitan las validaciones

  Future<Cuenta> cuenta(int id) async {
    final filas = await _db.query('cuentas', where: 'id = ?', whereArgs: [id]);
    if (filas.isEmpty) throw const ErrorLibro('La cuenta no existe');
    return Cuenta.desdeFila(filas.first);
  }

  Future<Dinero> saldo(int cuentaId) async {
    final c = await cuenta(cuentaId);
    final filas = await _db.rawQuery(
      'SELECT saldo_centavos FROM saldos_cuentas WHERE cuenta_id = ?',
      [cuentaId],
    );
    return Dinero((filas.first['saldo_centavos'] as num? ?? 0).toInt(), c.moneda);
  }

  Future<Movimiento> movimiento(int id) async {
    final filas = await _db.rawQuery('''
      SELECT m.*, c.moneda AS moneda, cd.moneda AS moneda_destino
      FROM movimientos m
      JOIN cuentas c ON c.id = m.cuenta_id
      LEFT JOIN cuentas cd ON cd.id = m.cuenta_destino_id
      WHERE m.id = ?
    ''', [id]);
    if (filas.isEmpty) throw const ErrorLibro('El movimiento ya no existe');
    return Movimiento.desdeFila(filas.first);
  }

  // ---------------------------------------------------------------------------
  // Ingresos y gastos

  /// Registra un ingreso o un gasto y devuelve su id.
  ///
  /// Un gasto puede dejar la cuenta en negativo: es un gasto que ya ocurrió y
  /// la app avisa, pero no lo bloquea.
  Future<int> registrar({
    required TipoMovimiento tipo,
    required Dinero monto,
    required int categoriaId,
    required DateTime fecha,
    String? descripcion,
    int cuentaId = Esquema.cuentaLibreArs,
    OrigenMovimiento origen = OrigenMovimiento.manual,
  }) async {
    await _validarIngresoOGasto(tipo, monto, categoriaId, cuentaId);
    return _db.insert('movimientos', {
      'tipo': tipo.valor,
      'fecha': fechaIso(fecha),
      'creado_en': DateTime.now().millisecondsSinceEpoch,
      'monto_centavos': monto.centavos,
      'cuenta_id': cuentaId,
      'categoria_id': categoriaId,
      'descripcion': _limpiar(descripcion),
      'origen': origen.valor,
    });
  }

  /// Cambia monto, categoría, fecha o descripción de un ingreso o gasto.
  Future<void> editar(
    int id, {
    required Dinero monto,
    required int categoriaId,
    required DateTime fecha,
    String? descripcion,
  }) async {
    final actual = await movimiento(id);
    if (!actual.esIngreso && !actual.esGasto) {
      throw const ErrorLibro('Solo se pueden editar ingresos y gastos');
    }
    await _validarIngresoOGasto(actual.tipo, monto, categoriaId, actual.cuentaId);
    await _db.update(
      'movimientos',
      {
        'monto_centavos': monto.centavos,
        'categoria_id': categoriaId,
        'fecha': fechaIso(fecha),
        'descripcion': _limpiar(descripcion),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _validarIngresoOGasto(TipoMovimiento tipo, Dinero monto, int categoriaId, int cuentaId) async {
    if (tipo != TipoMovimiento.ingreso && tipo != TipoMovimiento.gasto) {
      throw ArgumentError.value(tipo, 'tipo');
    }
    if (!monto.esPositivo) throw const ErrorLibro('Ingresá un monto mayor a cero');
    final c = await cuenta(cuentaId);
    if (c.moneda != monto.moneda) throw const ErrorLibro('La moneda no coincide con la cuenta');
    final categoria = await _db.query('categorias', columns: ['tipo'], where: 'id = ?', whereArgs: [categoriaId]);
    if (categoria.isEmpty) throw const ErrorLibro('La categoría no existe');
    if (categoria.first['tipo'] != tipo.valor) {
      throw ErrorLibro('La categoría no es de ${tipo == TipoMovimiento.gasto ? 'gastos' : 'ingresos'}');
    }
  }

  /// Borra un movimiento. Si generó un período de un plan, ese período queda
  /// libre (la aplicación se borra en cascada).
  ///
  /// No deja una meta en negativo: si la plata de un aporte ya se movió, hay
  /// que retirarla o moverla de vuelta antes.
  Future<void> eliminar(int id) async {
    final m = await movimiento(id);
    for (final cuentaId in [m.cuentaId, if (m.cuentaDestinoId != null) m.cuentaDestinoId!]) {
      if ((await cuenta(cuentaId)).archivada) {
        throw const ErrorLibro('Es de una meta eliminada: si se borra, esa plata quedaría escondida');
      }
    }
    await _db.delete('movimientos', where: 'id = ?', whereArgs: [id]);
    final entra = m.esTransferencia ? m.cuentaDestinoId : (m.esIngreso || m.tipo == TipoMovimiento.saldoInicial ? m.cuentaId : null);
    if (entra != null && (await cuenta(entra)).esMeta && (await saldo(entra)).esNegativo) {
      throw const ErrorLibro('Esa plata ya no está en la meta: retirala o movela antes de borrar el aporte');
    }
  }

  // ---------------------------------------------------------------------------
  // Transferencias

  /// Mueve plata entre dos cuentas en una sola fila.
  ///
  /// [monto] está en la moneda de origen. Si las monedas son distintas hace
  /// falta [montoDestino] en la moneda de destino. Nunca deja el origen en
  /// negativo.
  Future<int> transferir({
    required int origenId,
    required int destinoId,
    required Dinero monto,
    Dinero? montoDestino,
    required DateTime fecha,
    String? descripcion,
    OrigenMovimiento origen = OrigenMovimiento.manual,
  }) async {
    if (origenId == destinoId) throw const ErrorLibro('El origen y el destino son la misma cuenta');
    if (!monto.esPositivo) throw const ErrorLibro('Ingresá un monto mayor a cero');
    final desde = await cuenta(origenId);
    final hacia = await cuenta(destinoId);
    if (desde.archivada || hacia.archivada) throw const ErrorLibro('La cuenta está archivada');
    if (monto.moneda != desde.moneda) throw const ErrorLibro('La moneda no coincide con la cuenta de origen');
    if (hacia.moneda != desde.moneda) {
      if (montoDestino == null || !montoDestino.esPositivo || montoDestino.moneda != hacia.moneda) {
        throw const ErrorLibro('Falta la conversión de moneda');
      }
    } else if (montoDestino != null && montoDestino != monto) {
      throw const ErrorLibro('En la misma moneda entra lo mismo que sale');
    }

    final disponible = await saldo(origenId);
    if (monto > disponible) {
      throw ErrorLibro('No alcanza: en ${desde.nombre} hay ${disponible.formatear()}');
    }

    return _db.insert('movimientos', {
      'tipo': TipoMovimiento.transferencia.valor,
      'fecha': fechaIso(fecha),
      'creado_en': DateTime.now().millisecondsSinceEpoch,
      'monto_centavos': monto.centavos,
      'cuenta_id': origenId,
      'cuenta_destino_id': destinoId,
      'monto_destino_centavos': hacia.moneda != desde.moneda ? montoDestino!.centavos : null,
      'descripcion': _limpiar(descripcion),
      'origen': origen.valor,
    });
  }

  /// Reemplaza el saldo inicial ("ahorro previo") de una cuenta libre.
  Future<void> fijarSaldoInicial(int cuentaId, Dinero monto, {required DateTime fecha}) async {
    final c = await cuenta(cuentaId);
    if (c.esMeta) throw const ErrorLibro('El ahorro previo es de las cuentas libres');
    if (monto.moneda != c.moneda) throw const ErrorLibro('La moneda no coincide con la cuenta');
    if (monto.esNegativo) throw const ErrorLibro('El ahorro previo no puede ser negativo');
    await _db.delete('movimientos', where: "cuenta_id = ? AND tipo = 'saldo_inicial'", whereArgs: [cuentaId]);
    if (monto.esPositivo) {
      await _db.insert('movimientos', {
        'tipo': TipoMovimiento.saldoInicial.valor,
        'fecha': fechaIso(fecha),
        'creado_en': DateTime.now().millisecondsSinceEpoch,
        'monto_centavos': monto.centavos,
        'cuenta_id': cuentaId,
        'descripcion': 'Ahorro previo',
        'origen': OrigenMovimiento.manual.valor,
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Metas

  Future<int> crearMeta({
    required String nombre,
    required String icono,
    required Dinero objetivo,
    required DateTime fecha,
  }) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) throw const ErrorLibro('Ingresá un nombre para la meta');
    if (!objetivo.esPositivo) throw const ErrorLibro('Ingresá un monto objetivo válido');
    final cuentaId = await _db.insert('cuentas', {
      'nombre': limpio,
      'moneda': objetivo.moneda.codigo,
      'tipo': 'meta',
    });
    return _db.insert('metas', {
      'cuenta_id': cuentaId,
      'icono': icono,
      'monto_objetivo': objetivo.centavos,
      'fecha_creacion': fecha.millisecondsSinceEpoch,
    });
  }

  /// Cambia nombre, ícono u objetivo. La moneda solo se puede cambiar si la
  /// meta nunca tuvo movimientos.
  Future<void> editarMeta(int metaId, {required String nombre, required String icono, required Dinero objetivo}) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) throw const ErrorLibro('Ingresá un nombre para la meta');
    if (!objetivo.esPositivo) throw const ErrorLibro('Ingresá un monto objetivo válido');
    final cuentaId = await _cuentaDeMeta(metaId);
    final c = await cuenta(cuentaId);
    if (c.moneda != objetivo.moneda && await _tieneMovimientos(cuentaId)) {
      throw const ErrorLibro('No se puede cambiar la moneda de una meta con movimientos');
    }
    await _db.update('cuentas', {'nombre': limpio, 'moneda': objetivo.moneda.codigo},
        where: 'id = ?', whereArgs: [cuentaId]);
    await _db.update('metas', {'icono': icono, 'monto_objetivo': objetivo.centavos},
        where: 'id = ?', whereArgs: [metaId]);
  }

  /// Aporta [pesos] del disponible a una meta. Si la meta es en dólares se
  /// convierte con [cotizacion]. No deja pasar el objetivo de la meta.
  Future<int> aportarAMeta(
    int metaId,
    Dinero pesos, {
    double? cotizacion,
    required DateTime fecha,
    OrigenMovimiento origen = OrigenMovimiento.manual,
  }) async {
    final cuentaId = await _cuentaDeMeta(metaId);
    final meta = await cuenta(cuentaId);
    final entra = _convertir(pesos, meta.moneda, cotizacion);
    await _validarObjetivo(metaId, cuentaId, entra);
    return transferir(
      origenId: Esquema.cuentaLibreArs,
      destinoId: cuentaId,
      monto: pesos,
      montoDestino: meta.moneda == pesos.moneda ? null : entra,
      fecha: fecha,
      descripcion: 'Aporte a ${meta.nombre}',
      origen: origen,
    );
  }

  /// Retira [monto] (en la moneda de la meta) y lo devuelve al disponible.
  /// El historial no se toca: queda registrado como un retiro.
  Future<int> retirarDeMeta(int metaId, Dinero monto, {double? cotizacion, required DateTime fecha}) async {
    final cuentaId = await _cuentaDeMeta(metaId);
    final meta = await cuenta(cuentaId);
    final pesos = _convertir(monto, Moneda.ars, cotizacion);
    return transferir(
      origenId: cuentaId,
      destinoId: Esquema.cuentaLibreArs,
      monto: monto,
      montoDestino: monto.moneda == Moneda.ars ? null : pesos,
      fecha: fecha,
      descripcion: 'Retiro de ${meta.nombre}',
    );
  }

  /// Mueve [monto] (en la moneda de la meta origen) a otra meta.
  Future<int> moverEntreMetas(int origenId, int destinoId, Dinero monto, {double? cotizacion, required DateTime fecha}) async {
    if (origenId == destinoId) throw const ErrorLibro('Elegí otra meta');
    final cuentaOrigen = await _cuentaDeMeta(origenId);
    final cuentaDestino = await _cuentaDeMeta(destinoId);
    final desde = await cuenta(cuentaOrigen);
    final hacia = await cuenta(cuentaDestino);
    final entra = _convertir(monto, hacia.moneda, cotizacion);
    await _validarObjetivo(destinoId, cuentaDestino, entra);
    return transferir(
      origenId: cuentaOrigen,
      destinoId: cuentaDestino,
      monto: monto,
      montoDestino: desde.moneda == hacia.moneda ? null : entra,
      fecha: fecha,
      descripcion: 'De ${desde.nombre} a ${hacia.nombre}',
    );
  }

  /// Elimina una meta: su plata vuelve al disponible con un retiro y la
  /// cuenta queda archivada para que el historial siga intacto.
  Future<void> eliminarMeta(int metaId, {double? cotizacion, required DateTime fecha}) async {
    final cuentaId = await _cuentaDeMeta(metaId);
    final saldoMeta = await saldo(cuentaId);
    if (saldoMeta.esNegativo) throw const ErrorLibro('La meta tiene saldo negativo');
    if (saldoMeta.esPositivo) {
      await retirarDeMeta(metaId, saldoMeta, cotizacion: cotizacion, fecha: fecha);
    }
    await _db.delete('metas', where: 'id = ?', whereArgs: [metaId]);
    if (await _tieneMovimientos(cuentaId)) {
      await _db.update('cuentas', {'archivada': 1}, where: 'id = ?', whereArgs: [cuentaId]);
    } else {
      await _db.delete('cuentas', where: 'id = ?', whereArgs: [cuentaId]);
    }
  }

  Future<int> _cuentaDeMeta(int metaId) async {
    final filas = await _db.query('metas', columns: ['cuenta_id'], where: 'id = ?', whereArgs: [metaId]);
    if (filas.isEmpty) throw const ErrorLibro('La meta no existe');
    return filas.first['cuenta_id'] as int;
  }

  Future<bool> _tieneMovimientos(int cuentaId) async {
    final filas = await _db.rawQuery(
      'SELECT 1 FROM movimientos WHERE cuenta_id = ? OR cuenta_destino_id = ? LIMIT 1',
      [cuentaId, cuentaId],
    );
    return filas.isNotEmpty;
  }

  /// No se puede pasar el objetivo (con 1 centavo de tolerancia por redondeo
  /// de la conversión).
  Future<void> _validarObjetivo(int metaId, int cuentaId, Dinero entra) async {
    final filas = await _db.query('metas', columns: ['monto_objetivo'], where: 'id = ?', whereArgs: [metaId]);
    final objetivo = Dinero(filas.first['monto_objetivo'] as int, entra.moneda);
    final falta = objetivo - await saldo(cuentaId);
    if (entra.centavos > falta.centavos + 1) {
      throw ErrorLibro(falta.esPositivo
          ? 'A la meta solo le faltan ${falta.formatear()}'
          : 'La meta ya está completa');
    }
  }

  Dinero _convertir(Dinero monto, Moneda destino, double? cotizacion) {
    if (monto.moneda == destino) return monto;
    if (cotizacion == null || cotizacion <= 0) {
      throw const ErrorLibro('Esperá a que cargue la cotización del dólar');
    }
    return monto.convertir(destino, cotizacion);
  }

  static String? _limpiar(String? texto) {
    final t = texto?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
