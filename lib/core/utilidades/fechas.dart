/// Fechas del libro: los movimientos guardan la fecha local como texto
/// `YYYY-MM-DD` y los planes trabajan por mes (`YYYY-MM`).
library;

String _dos(int n) => n.toString().padLeft(2, '0');

/// `2026-10-05` (fecha local, sin hora).
String fechaIso(DateTime fecha) => '${fecha.year}-${_dos(fecha.month)}-${_dos(fecha.day)}';

/// Inversa de [fechaIso]: medianoche local de ese día.
DateTime desdeFechaIso(String texto) {
  final partes = texto.split('-');
  return DateTime(int.parse(partes[0]), int.parse(partes[1]), int.parse(partes[2]));
}

/// Un mes calendario (`2026-10`).
class Periodo implements Comparable<Periodo> {
  const Periodo(this.anio, this.mes) : assert(mes >= 1 && mes <= 12);

  factory Periodo.de(DateTime fecha) => Periodo(fecha.year, fecha.month);

  factory Periodo.parsear(String texto) {
    final partes = texto.split('-');
    return Periodo(int.parse(partes[0]), int.parse(partes[1]));
  }

  final int anio;
  final int mes;

  /// Suma (o resta) meses cruzando años: diciembre + 1 = enero siguiente.
  Periodo sumar(int meses) {
    final indice = anio * 12 + (mes - 1) + meses;
    return Periodo(indice ~/ 12, indice % 12 + 1);
  }

  Periodo get siguiente => sumar(1);
  Periodo get anterior => sumar(-1);

  /// Meses de [otro] a este (positivo si este es posterior).
  int mesesDesde(Periodo otro) => (anio * 12 + mes) - (otro.anio * 12 + otro.mes);

  DateTime get primerDia => DateTime(anio, mes);
  int get diasDelMes => DateTime(anio, mes + 1, 0).day;

  /// Primer día del mes y primer día del mes siguiente, como texto ISO, para
  /// filtrar `fecha >= desde AND fecha < hasta`.
  String get desde => '$anio-${_dos(mes)}-01';
  String get hasta => siguiente.desde;

  /// Fecha de débito dentro del mes, acotada al último día.
  DateTime fechaDelDia(int dia) => DateTime(anio, mes, dia.clamp(1, diasDelMes));

  bool operator <(Periodo otro) => compareTo(otro) < 0;
  bool operator <=(Periodo otro) => compareTo(otro) <= 0;
  bool operator >(Periodo otro) => compareTo(otro) > 0;
  bool operator >=(Periodo otro) => compareTo(otro) >= 0;

  @override
  int compareTo(Periodo otro) => mesesDesde(otro).sign;

  @override
  bool operator ==(Object other) => other is Periodo && other.anio == anio && other.mes == mes;

  @override
  int get hashCode => Object.hash(anio, mes);

  @override
  String toString() => '$anio-${_dos(mes)}';
}
