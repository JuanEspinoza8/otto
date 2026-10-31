import '../../dinero/dinero.dart';
import '../../utilidades/fechas.dart';

enum TipoMovimiento {
  ingreso('ingreso'),
  gasto('gasto'),
  transferencia('transferencia'),
  saldoInicial('saldo_inicial');

  const TipoMovimiento(this.valor);

  /// Valor guardado en la columna `tipo`.
  final String valor;

  static TipoMovimiento desdeValor(String valor) =>
      values.firstWhere((t) => t.valor == valor);
}

enum OrigenMovimiento {
  manual('manual'),
  plan('plan'),
  ia('ia'),
  importado('import'),
  migracion('migracion');

  const OrigenMovimiento(this.valor);
  final String valor;

  static OrigenMovimiento desdeValor(String? valor) =>
      values.firstWhere((o) => o.valor == valor, orElse: () => manual);
}

/// Una fila del libro.
///
/// - Ingreso y gasto: entran o salen de [cuentaId] y tienen categoría.
/// - Transferencia: sale [monto] de [cuentaId] y entra [montoDestino] (o el
///   mismo monto si es la misma moneda) en [cuentaDestinoId].
/// - Saldo inicial: plata que ya estaba en la cuenta antes de usar la app.
class Movimiento {
  const Movimiento({
    this.id,
    required this.tipo,
    required this.fecha,
    required this.monto,
    required this.cuentaId,
    this.cuentaDestinoId,
    this.montoDestino,
    this.categoriaId,
    this.descripcion,
    this.origen = OrigenMovimiento.manual,
    this.creadoEn,
  });

  final int? id;
  final TipoMovimiento tipo;

  /// Día del movimiento (sin hora).
  final DateTime fecha;
  final Dinero monto;
  final int cuentaId;
  final int? cuentaDestinoId;
  final Dinero? montoDestino;
  final int? categoriaId;
  final String? descripcion;
  final OrigenMovimiento origen;
  final DateTime? creadoEn;

  bool get esIngreso => tipo == TipoMovimiento.ingreso;
  bool get esGasto => tipo == TipoMovimiento.gasto;
  bool get esTransferencia => tipo == TipoMovimiento.transferencia;

  /// Lo que entra a la cuenta destino de una transferencia.
  Dinero get montoQueEntra => montoDestino ?? monto;

  /// Lee una fila que incluye la moneda de las cuentas (`moneda` y
  /// `moneda_destino`, ver las consultas del libro).
  factory Movimiento.desdeFila(Map<String, Object?> fila) {
    final moneda = Moneda.desdeCodigo(fila['moneda'] as String?);
    final destino = fila['monto_destino_centavos'] as int?;
    return Movimiento(
      id: fila['id'] as int?,
      tipo: TipoMovimiento.desdeValor(fila['tipo'] as String),
      fecha: desdeFechaIso(fila['fecha'] as String),
      monto: Dinero(fila['monto_centavos'] as int, moneda),
      cuentaId: fila['cuenta_id'] as int,
      cuentaDestinoId: fila['cuenta_destino_id'] as int?,
      montoDestino: destino == null
          ? null
          : Dinero(destino, Moneda.desdeCodigo(fila['moneda_destino'] as String?)),
      categoriaId: fila['categoria_id'] as int?,
      descripcion: fila['descripcion'] as String?,
      origen: OrigenMovimiento.desdeValor(fila['origen'] as String?),
      creadoEn: fila['creado_en'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(fila['creado_en'] as int),
    );
  }
}
