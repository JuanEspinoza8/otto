import '../../../features/categorias/modelo/categoria.dart';
import '../../dinero/dinero.dart';
import '../../libro/modelo/cuenta.dart';
import '../../libro/modelo/meta.dart';
import '../../libro/modelo/movimiento.dart';

enum SentidoMovimiento { entra, sale, aMeta, desdeMeta, entreMetas }

/// Cómo se ve un movimiento en las listas: nombre, color, ícono y el monto
/// que importa (en una transferencia, el lado en pesos si lo hay).
class PresentacionMovimiento {
  const PresentacionMovimiento({
    required this.etiqueta,
    required this.colorHex,
    required this.icono,
    required this.monto,
    required this.sentido,
  });

  final String etiqueta;
  final String colorHex;
  final String icono;
  final Dinero monto;
  final SentidoMovimiento sentido;

  bool get esTransferencia =>
      sentido == SentidoMovimiento.aMeta ||
      sentido == SentidoMovimiento.desdeMeta ||
      sentido == SentidoMovimiento.entreMetas;

  String get signo => switch (sentido) {
        SentidoMovimiento.entra || SentidoMovimiento.desdeMeta => '+',
        SentidoMovimiento.sale => '-',
        SentidoMovimiento.aMeta || SentidoMovimiento.entreMetas => '→ ',
      };

  static const String _azul = '0xFF3B82F6';

  factory PresentacionMovimiento.de(
    Movimiento m, {
    required List<Categoria> categorias,
    required Map<int, Cuenta> cuentas,
    required Iterable<Meta> metas,
  }) {
    if (!m.esTransferencia) {
      final coincide = categorias.where((c) => c.id == m.categoriaId);
      final categoria = coincide.isEmpty ? null : coincide.first;
      return PresentacionMovimiento(
        etiqueta: categoria?.nombre ?? (m.esIngreso ? 'Ingreso' : 'Gasto'),
        colorHex: categoria?.colorHex ?? '0xFF9E9E9E',
        icono: categoria?.icono ?? 'category',
        monto: m.monto,
        sentido: m.esIngreso ? SentidoMovimiento.entra : SentidoMovimiento.sale,
      );
    }

    final desde = cuentas[m.cuentaId];
    final hacia = cuentas[m.cuentaDestinoId];
    String iconoDe(Cuenta? c) {
      final meta = metas.where((x) => x.cuentaId == c?.id);
      return meta.isEmpty ? 'savings' : meta.first.icono;
    }

    if (hacia != null && hacia.esMeta && (desde == null || !desde.esMeta)) {
      return PresentacionMovimiento(
        etiqueta: hacia.nombre,
        colorHex: _azul,
        icono: iconoDe(hacia),
        monto: m.monto,
        sentido: SentidoMovimiento.aMeta,
      );
    }
    if (desde != null && desde.esMeta && (hacia == null || !hacia.esMeta)) {
      return PresentacionMovimiento(
        etiqueta: desde.nombre,
        colorHex: _azul,
        icono: iconoDe(desde),
        monto: m.montoQueEntra,
        sentido: SentidoMovimiento.desdeMeta,
      );
    }
    return PresentacionMovimiento(
      etiqueta: '${desde?.nombre ?? '?'} → ${hacia?.nombre ?? '?'}',
      colorHex: _azul,
      icono: 'savings',
      monto: m.monto,
      sentido: SentidoMovimiento.entreMetas,
    );
  }
}
