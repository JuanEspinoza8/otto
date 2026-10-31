import '../../dinero/dinero.dart';

enum TipoCuenta { libre, meta }

/// Una cuenta del libro: "Libre ARS", "Dólares" o la cuenta de una meta.
class Cuenta {
  const Cuenta({
    required this.id,
    required this.nombre,
    required this.moneda,
    required this.tipo,
    this.archivada = false,
  });

  final int id;
  final String nombre;
  final Moneda moneda;
  final TipoCuenta tipo;
  final bool archivada;

  bool get esMeta => tipo == TipoCuenta.meta;

  factory Cuenta.desdeFila(Map<String, Object?> fila) => Cuenta(
        id: fila['id'] as int,
        nombre: fila['nombre'] as String,
        moneda: Moneda.desdeCodigo(fila['moneda'] as String?),
        tipo: fila['tipo'] == 'meta' ? TipoCuenta.meta : TipoCuenta.libre,
        archivada: fila['archivada'] == 1,
      );
}
