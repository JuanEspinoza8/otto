import '../../../core/dinero/dinero.dart';
import '../../../core/utilidades/fechas.dart';

enum TipoPlan {
  fijo('fijo'),
  cuotas('cuotas'),
  sueldo('sueldo');

  const TipoPlan(this.valor);
  final String valor;

  static TipoPlan desdeValor(String valor) => values.firstWhere((t) => t.valor == valor);
}

/// Un compromiso mensual: un gasto fijo, una compra en cuotas o el sueldo.
///
/// Cada mes confirmado es una aplicación (`plan_aplicaciones`). Las cuotas
/// pagadas son la cantidad de aplicaciones, así que borrar el gasto generado
/// libera ese mes y descuenta la cuota.
class Plan {
  const Plan({
    this.id,
    required this.tipo,
    required this.nombre,
    this.categoriaId,
    required this.monto,
    this.total,
    this.totalCuotas,
    required this.primerPeriodo,
    this.diaDebito = 1,
    this.activo = true,
    this.periodosAplicados = const {},
  });

  final int? id;
  final TipoPlan tipo;
  final String nombre;
  final int? categoriaId;

  /// Monto mensual (en cuotas: el de cada cuota menos la última).
  final Dinero monto;

  /// Total de la compra (solo cuotas).
  final Dinero? total;
  final int? totalCuotas;
  final Periodo primerPeriodo;
  final int diaDebito;
  final bool activo;
  final Set<Periodo> periodosAplicados;

  bool get esIngreso => tipo == TipoPlan.sueldo;
  bool get esCuotas => tipo == TipoPlan.cuotas;

  int get cuotasPagadas => periodosAplicados.length;
  int get cuotasRestantes => esCuotas ? (totalCuotas! - cuotasPagadas).clamp(0, totalCuotas!) : 0;
  bool get terminado => esCuotas && cuotasPagadas >= totalCuotas!;

  double get porcentajePagado =>
      esCuotas && totalCuotas! > 0 ? (cuotasPagadas / totalCuotas! * 100).clamp(0, 100).toDouble() : 0;

  /// Monto de la cuota número [numero] (desde 1): todas valen
  /// `floor(total / N)` y la última absorbe el resto del redondeo.
  Dinero montoDeCuota(int numero) {
    if (!esCuotas) return monto;
    final n = totalCuotas!;
    final base = total!.centavos ~/ n;
    return Dinero(numero >= n ? total!.centavos - base * (n - 1) : base, total!.moneda);
  }

  /// Lo que falta pagar de una compra en cuotas.
  Dinero get montoRestante {
    if (!esCuotas) return Dinero.cero(monto.moneda);
    var restante = Dinero.cero(monto.moneda);
    for (var k = cuotasPagadas + 1; k <= totalCuotas!; k++) {
      restante += montoDeCuota(k);
    }
    return restante;
  }

  /// Cuotas que se crean con un total y una cantidad.
  static Dinero cuotaBase(Dinero total, int cantidad) => Dinero(total.centavos ~/ cantidad, total.moneda);

  Map<String, Object?> aFila() => {
        if (id != null) 'id': id,
        'tipo': tipo.valor,
        'nombre': nombre.trim(),
        'categoria_id': categoriaId,
        'monto_centavos': monto.centavos,
        'total_centavos': total?.centavos,
        'total_cuotas': totalCuotas,
        'primer_periodo': primerPeriodo.toString(),
        'dia_debito': diaDebito.clamp(1, 28),
        'activo': activo ? 1 : 0,
      };

  factory Plan.desdeFila(Map<String, Object?> fila, Set<Periodo> aplicados) {
    final total = fila['total_centavos'] as int?;
    return Plan(
      id: fila['id'] as int,
      tipo: TipoPlan.desdeValor(fila['tipo'] as String),
      nombre: fila['nombre'] as String,
      categoriaId: fila['categoria_id'] as int?,
      monto: Dinero(fila['monto_centavos'] as int),
      total: total == null ? null : Dinero(total),
      totalCuotas: fila['total_cuotas'] as int?,
      primerPeriodo: Periodo.parsear(fila['primer_periodo'] as String),
      diaDebito: fila['dia_debito'] as int,
      activo: fila['activo'] == 1,
      periodosAplicados: aplicados,
    );
  }

  Plan copiaCon({
    String? nombre,
    int? categoriaId,
    Dinero? monto,
    Dinero? total,
    int? totalCuotas,
    int? diaDebito,
    bool? activo,
  }) =>
      Plan(
        id: id,
        tipo: tipo,
        nombre: nombre ?? this.nombre,
        categoriaId: categoriaId ?? this.categoriaId,
        monto: monto ?? this.monto,
        total: total ?? this.total,
        totalCuotas: totalCuotas ?? this.totalCuotas,
        primerPeriodo: primerPeriodo,
        diaDebito: diaDebito ?? this.diaDebito,
        activo: activo ?? this.activo,
        periodosAplicados: periodosAplicados,
      );
}

/// Un período de un plan que falta confirmar.
class Pendiente {
  const Pendiente({required this.plan, required this.periodo, required this.monto, required this.numeroCuota});

  final Plan plan;
  final Periodo periodo;
  final Dinero monto;

  /// Número de cuota que se pagaría (solo cuotas).
  final int? numeroCuota;

  String get descripcion => plan.esCuotas
      ? '${plan.nombre} (cuota $numeroCuota/${plan.totalCuotas})'
      : plan.nombre;

  DateTime get fecha => periodo.fechaDelDia(plan.diaDebito);
}

/// Pendientes de [mes]: solo el mes actual y el anterior, desde el
/// `primerPeriodo` de cada plan, y en el mes actual recién desde su día de
/// débito.
List<Pendiente> calcularPendientes(List<Plan> planes, Periodo mes, DateTime hoy) {
  final actual = Periodo.de(hoy);
  if (mes > actual || mes < actual.anterior) return [];
  final resultado = <Pendiente>[];
  for (final plan in planes) {
    if (!plan.activo || plan.id == null) continue;
    if (mes < plan.primerPeriodo || plan.periodosAplicados.contains(mes)) continue;
    if (plan.terminado) continue;
    if (mes == actual && hoy.day < plan.diaDebito) continue;
    final numero = plan.esCuotas ? plan.cuotasPagadas + 1 : null;
    resultado.add(Pendiente(
      plan: plan,
      periodo: mes,
      monto: plan.esCuotas ? plan.montoDeCuota(numero!) : plan.monto,
      numeroCuota: numero,
    ));
  }
  // Primero el sueldo, después por día de débito.
  resultado.sort((a, b) {
    if (a.plan.esIngreso != b.plan.esIngreso) return a.plan.esIngreso ? -1 : 1;
    return a.plan.diaDebito.compareTo(b.plan.diaDebito);
  });
  return resultado;
}
