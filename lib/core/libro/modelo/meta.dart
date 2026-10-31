import '../../dinero/dinero.dart';

/// Una meta de ahorro. Su plata es el saldo de su cuenta en el libro.
class Meta {
  const Meta({
    required this.id,
    required this.cuentaId,
    required this.nombre,
    required this.icono,
    required this.objetivo,
    required this.saldo,
    required this.fechaCreacion,
  });

  final int id;
  final int cuentaId;
  final String nombre;
  final String icono;
  final Dinero objetivo;
  final Dinero saldo;
  final DateTime fechaCreacion;

  Moneda get moneda => objetivo.moneda;
  bool get esUsd => moneda == Moneda.usd;

  /// Lo que falta para el objetivo (nunca negativo).
  Dinero get falta => (objetivo - saldo).max(Dinero.cero(moneda));

  /// Progreso de 0 a 100, truncado.
  int get porcentajeProgreso => saldo.porcentajeDe(objetivo).clamp(0, 100);

  bool get cumplida => objetivo.esPositivo && saldo >= objetivo;

  /// Fila de `metas` unida a su cuenta y a `saldos_cuentas`.
  factory Meta.desdeFila(Map<String, Object?> fila) {
    final moneda = Moneda.desdeCodigo(fila['moneda'] as String?);
    return Meta(
      id: fila['id'] as int,
      cuentaId: fila['cuenta_id'] as int,
      nombre: fila['nombre'] as String,
      icono: fila['icono'] as String,
      objetivo: Dinero(fila['monto_objetivo'] as int, moneda),
      saldo: Dinero((fila['saldo_centavos'] as num? ?? 0).toInt(), moneda),
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(fila['fecha_creacion'] as int),
    );
  }
}
