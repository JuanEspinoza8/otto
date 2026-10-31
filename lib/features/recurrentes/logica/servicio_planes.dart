import 'package:sqflite/sqflite.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/libro/modelo/movimiento.dart';
import '../../../core/libro/servicio_libro.dart';
import '../../../core/utilidades/fechas.dart';
import '../modelo/plan.dart';

/// Lectura y escritura de planes (sueldo, fijos y cuotas).
///
/// Confirmar un período escribe la aplicación y el movimiento en la misma
/// transacción, y la clave primaria (plan, período) impide duplicarlo aunque
/// se toque dos veces el botón.
class ServicioPlanes {
  ServicioPlanes(this._db);

  final DatabaseExecutor _db;

  ServicioLibro get _libro => ServicioLibro(_db);

  static Future<T> transaccion<T>(Database db, Future<T> Function(ServicioPlanes planes) accion) =>
      db.transaction((txn) => accion(ServicioPlanes(txn)));

  // ---------------------------------------------------------------------------
  // Lectura

  Future<List<Plan>> planes({TipoPlan? tipo}) async {
    final filas = await _db.query(
      'planes',
      where: tipo == null ? null : 'tipo = ?',
      whereArgs: tipo == null ? null : [tipo.valor],
      orderBy: 'id DESC',
    );
    final aplicaciones = await _db.query('plan_aplicaciones', columns: ['plan_id', 'periodo']);
    final porPlan = <int, Set<Periodo>>{};
    for (final a in aplicaciones) {
      porPlan.putIfAbsent(a['plan_id'] as int, () => {}).add(Periodo.parsear(a['periodo'] as String));
    }
    return [for (final f in filas) Plan.desdeFila(f, porPlan[f['id']] ?? {})];
  }

  Future<Plan> plan(int id) async {
    final filas = await _db.query('planes', where: 'id = ?', whereArgs: [id]);
    if (filas.isEmpty) throw const ErrorLibro('El plan ya no existe');
    final aplicaciones = await _db.query('plan_aplicaciones', columns: ['periodo'], where: 'plan_id = ?', whereArgs: [id]);
    return Plan.desdeFila(filas.first, {for (final a in aplicaciones) Periodo.parsear(a['periodo'] as String)});
  }

  Future<Plan?> sueldo() async {
    final lista = await planes(tipo: TipoPlan.sueldo);
    return lista.isEmpty ? null : lista.first;
  }

  // ---------------------------------------------------------------------------
  // Alta, edición y baja

  Future<int> crear(Plan plan) async {
    _validar(plan);
    final fila = plan.aFila()..remove('id');
    return _db.insert('planes', fila);
  }

  /// Crea una compra en cuotas. Las [yaPagadas] antes de cargarla en la app
  /// ocupan los meses previos, sin movimiento (no descuentan del disponible).
  Future<int> crearCuotas(Plan plan, {int yaPagadas = 0}) async {
    final previas = yaPagadas.clamp(0, plan.totalCuotas ?? 0);
    final primero = plan.primerPeriodo.sumar(-previas);
    final id = await crear(Plan(
      tipo: TipoPlan.cuotas,
      nombre: plan.nombre,
      categoriaId: plan.categoriaId,
      monto: plan.monto,
      total: plan.total,
      totalCuotas: plan.totalCuotas,
      primerPeriodo: primero,
      diaDebito: plan.diaDebito,
      activo: plan.activo,
    ));
    for (var i = 0; i < previas; i++) {
      await marcarSinMovimiento(id, primero.sumar(i));
    }
    return id;
  }

  Future<void> actualizar(Plan plan) async {
    _validar(plan);
    final actual = await this.plan(plan.id!);
    if (plan.esCuotas && plan.totalCuotas! < actual.cuotasPagadas) {
      throw ErrorLibro('Ya se pagaron ${actual.cuotasPagadas} cuotas');
    }
    final fila = plan.aFila()
      ..remove('id')
      ..remove('tipo')
      ..remove('primer_periodo');
    // Un sueldo o un fijo que vuelve de una pausa arranca este mes: los meses
    // en pausa no aparecen como pendientes. Las cuotas conservan su inicio.
    if (!actual.activo && plan.activo && !plan.esCuotas) {
      final hoy = Periodo.de(DateTime.now());
      if (actual.primerPeriodo < hoy) fila['primer_periodo'] = hoy.toString();
    }
    await _db.update('planes', fila, where: 'id = ?', whereArgs: [plan.id]);
  }

  /// Borra el plan y sus aplicaciones. Los gastos ya generados quedan.
  Future<void> eliminar(int id) => _db.delete('planes', where: 'id = ?', whereArgs: [id]);

  void _validar(Plan plan) {
    if (plan.nombre.trim().isEmpty) throw const ErrorLibro('Ingresá un nombre');
    if (!plan.monto.esPositivo) throw const ErrorLibro('Ingresá un monto mayor a cero');
    if (plan.esCuotas) {
      if (plan.totalCuotas == null || plan.totalCuotas! < 1) throw const ErrorLibro('Ingresá la cantidad de cuotas');
      if (plan.total == null || plan.total!.centavos < plan.totalCuotas!) {
        throw const ErrorLibro('El total no alcanza para esa cantidad de cuotas');
      }
    }
  }

  /// Crea, actualiza o pausa el plan del sueldo.
  Future<void> fijarSueldo(Dinero monto, {required DateTime hoy}) async {
    final actual = await sueldo();
    if (actual == null) {
      if (!monto.esPositivo) return;
      await crear(Plan(
        tipo: TipoPlan.sueldo,
        nombre: 'Sueldo',
        categoriaId: await _categoria('ingreso', 'sueldo'),
        monto: monto,
        primerPeriodo: Periodo.de(hoy),
      ));
      return;
    }
    if (!monto.esPositivo) {
      await _db.update('planes', {'activo': 0}, where: 'id = ?', whereArgs: [actual.id]);
      return;
    }
    await actualizar(actual.copiaCon(monto: monto, activo: true));
  }

  // ---------------------------------------------------------------------------
  // Aplicaciones

  /// Confirma el [periodo] de un plan: crea el ingreso o gasto y lo enlaza.
  /// Devuelve false si ese período ya estaba confirmado.
  Future<bool> confirmar(int planId, Periodo periodo, {DateTime? fecha}) async {
    final p = await plan(planId);
    if (periodo < p.primerPeriodo) throw const ErrorLibro('El plan empieza después');
    if (p.terminado) throw const ErrorLibro('Ya están todas las cuotas pagadas');

    await _db.rawInsert(
      'INSERT OR IGNORE INTO plan_aplicaciones (plan_id, periodo) VALUES (?, ?)',
      [planId, periodo.toString()],
    );
    final cambios = await _db.rawQuery('SELECT changes() AS n');
    if ((cambios.first['n'] as int) == 0) return false;

    final pendiente = Pendiente(
      plan: p,
      periodo: periodo,
      monto: p.esCuotas ? p.montoDeCuota(p.cuotasPagadas + 1) : p.monto,
      numeroCuota: p.esCuotas ? p.cuotasPagadas + 1 : null,
    );
    final movimientoId = await _libro.registrar(
      tipo: p.esIngreso ? TipoMovimiento.ingreso : TipoMovimiento.gasto,
      monto: pendiente.monto,
      categoriaId: await categoriaPara(p),
      fecha: fecha ?? pendiente.fecha,
      descripcion: pendiente.descripcion,
      origen: OrigenMovimiento.plan,
    );
    await _db.update(
      'plan_aplicaciones',
      {'movimiento_id': movimientoId},
      where: 'plan_id = ? AND periodo = ?',
      whereArgs: [planId, periodo.toString()],
    );
    return true;
  }

  /// Enlaza un movimiento ya registrado con el período de un plan (por
  /// ejemplo, el Netflix que se cargó desde el chat). Devuelve false si ese
  /// período ya estaba resuelto.
  Future<bool> enlazar(int planId, Periodo periodo, int movimientoId) async {
    await _db.rawInsert(
      'INSERT OR IGNORE INTO plan_aplicaciones (plan_id, periodo, movimiento_id) VALUES (?, ?, ?)',
      [planId, periodo.toString(), movimientoId],
    );
    final cambios = await _db.rawQuery('SELECT changes() AS n');
    return (cambios.first['n'] as int) > 0;
  }

  /// Marca el período como resuelto sin crear un movimiento ("ya lo cargué").
  Future<void> marcarSinMovimiento(int planId, Periodo periodo) => _db.rawInsert(
        'INSERT OR IGNORE INTO plan_aplicaciones (plan_id, periodo) VALUES (?, ?)',
        [planId, periodo.toString()],
      );

  /// Paga [cantidad] cuotas juntas con un solo gasto. Ocupan los primeros
  /// meses sin pagar del plan; si se borra el gasto, se liberan todos.
  Future<int> adelantarCuotas(int planId, int cantidad, {required DateTime fecha}) async {
    final p = await plan(planId);
    if (!p.esCuotas) throw const ErrorLibro('Solo se adelantan cuotas');
    if (p.terminado) throw const ErrorLibro('Ya están todas las cuotas pagadas');
    if (cantidad < 1) throw const ErrorLibro('Elegí cuántas cuotas pagar');
    final n = cantidad.clamp(1, p.cuotasRestantes);

    final periodos = <Periodo>[];
    var periodo = p.primerPeriodo;
    while (periodos.length < n) {
      if (!p.periodosAplicados.contains(periodo)) periodos.add(periodo);
      periodo = periodo.siguiente;
    }
    var total = Dinero.cero(p.monto.moneda);
    for (var k = p.cuotasPagadas + 1; k <= p.cuotasPagadas + n; k++) {
      total += p.montoDeCuota(k);
    }

    final movimientoId = await _libro.registrar(
      tipo: TipoMovimiento.gasto,
      monto: total,
      categoriaId: await categoriaPara(p),
      fecha: fecha,
      descripcion: n == 1
          ? '${p.nombre} (cuota ${p.cuotasPagadas + 1}/${p.totalCuotas})'
          : '${p.nombre} (cuotas ${p.cuotasPagadas + 1} a ${p.cuotasPagadas + n} de ${p.totalCuotas})',
      origen: OrigenMovimiento.plan,
    );
    for (final pe in periodos) {
      await _db.insert('plan_aplicaciones', {
        'plan_id': planId,
        'periodo': pe.toString(),
        'movimiento_id': movimientoId,
      });
    }
    return movimientoId;
  }

  /// Categoría del movimiento de un plan: la suya si sigue existiendo, si no
  /// "Sueldo", "Deudas" u "Otros Gastos" según el tipo.
  Future<int> categoriaPara(Plan p) async {
    final tipo = p.esIngreso ? 'ingreso' : 'gasto';
    if (p.categoriaId != null) {
      final existe = await _db.query('categorias', where: 'id = ? AND tipo = ?', whereArgs: [p.categoriaId, tipo]);
      if (existe.isNotEmpty) return p.categoriaId!;
    }
    return _categoria(tipo, p.tipo.categoriaPorDefecto);
  }

  Future<int> _categoria(String tipo, String nombre) async {
    final exacta = await _db.query('categorias',
        where: 'tipo = ? AND LOWER(nombre) = ?', whereArgs: [tipo, nombre], limit: 1);
    if (exacta.isNotEmpty) return exacta.first['id'] as int;
    final otros = await _db.query('categorias',
        where: "tipo = ? AND LOWER(nombre) LIKE 'otros%'", whereArgs: [tipo], limit: 1);
    if (otros.isNotEmpty) return otros.first['id'] as int;
    final cualquiera = await _db.query('categorias', where: 'tipo = ?', whereArgs: [tipo], limit: 1);
    if (cualquiera.isEmpty) throw ErrorLibro('No hay categorías de $tipo');
    return cualquiera.first['id'] as int;
  }
}
