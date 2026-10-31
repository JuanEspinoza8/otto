import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/utilidades/fechas.dart';
import '../../../core/utilidades/mapeador_iconos.dart';
import '../../../core/ui/widgets/mascota_otto.dart';
import '../../configuracion/logica/ajustes_provider.dart';
import '../../otto/logica/contador_provider.dart';
import '../logica/dashboard_provider.dart';
import '../logica/servicio_resumen_mes.dart';

/// Pantalla de resumen de un mes: ingresos, egresos por categoría y sobrante,
/// con una devolución de la IA en rol de contador.
class PantallaResumenMes extends ConsumerStatefulWidget {
  final DateTime mes;
  const PantallaResumenMes({super.key, required this.mes});

  static Future<void> mostrar(BuildContext context, DateTime mes) {
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => PantallaResumenMes(mes: mes)));
  }

  @override
  ConsumerState<PantallaResumenMes> createState() => _PantallaResumenMesState();
}

class _PantallaResumenMesState extends ConsumerState<PantallaResumenMes> {
  @override
  Widget build(BuildContext context) {
    final mesTxt = capitalizarMes(DateFormat('MMMM yyyy', 'es').format(widget.mes));
    final r = ref.watch(resumenDeMesProvider(Periodo.de(widget.mes))).valueOrNull;

    return Scaffold(
      backgroundColor: context.colores.fondo,
      appBar: AppBar(
        backgroundColor: context.colores.fondo,
        iconTheme: IconThemeData(color: context.colores.textoPrimario),
        title: Text('Resumen de $mesTxt', style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
      ),
      body: r == null
          ? const Center(child: CircularProgressIndicator())
          : (r.vacio
              ? Center(child: Text('No hubo movimientos en $mesTxt', style: TextStyle(color: context.colores.textoSecundario)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: Text('INGRESOS DEL MES', style: TextStyle(color: context.colores.textoSecundario, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: FittedBox(
                        child: Text(r.totalIngresos.formatear(),
                            style: const TextStyle(color: TemaApp.verde, fontSize: 48, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...r.ingresos.map((l) => _fila(context, l, esIngreso: true)),
                    const SizedBox(height: 20),
                    Text('SE FUE EN…', style: TextStyle(color: context.colores.textoSecundario, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    if (r.egresos.isEmpty)
                      Text('No hubo gastos este mes 🎉', style: TextStyle(color: context.colores.textoSecundario))
                    else
                      ...r.egresos.map((l) => _fila(context, l, esIngreso: false)),
                    const SizedBox(height: 20),
                    // Sobrante final
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.colores.superficie,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: (r.sobrante.esNegativo ? TemaApp.rojo : TemaApp.verde).withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          Text('TE QUEDÓ', style: TextStyle(color: context.colores.textoSecundario, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 6),
                          FittedBox(
                            child: Text(r.sobrante.formatear(),
                                style: TextStyle(color: r.sobrante.esNegativo ? TemaApp.rojo : TemaApp.verde, fontSize: 40, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _tarjetaContador(context),
                    const SizedBox(height: 24),
                  ],
                )),
    );
  }

  Widget _fila(BuildContext context, LineaResumen l, {required bool esIngreso}) {
    final color = Color(int.parse(l.colorHex));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(MapeadorIconos.obtenerIcono(l.icono), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(l.nombre, style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.w600))),
          Text('${esIngreso ? '+' : '-'}${l.monto.formatear()}',
              style: TextStyle(color: esIngreso ? TemaApp.verde : TemaApp.rojo, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _tarjetaContador(BuildContext context) {
    final devolucion = ref.watch(devolucionContadorProvider(Periodo.de(widget.mes)));
    final iaActiva = ref.watch(ajustesControladorProvider).valueOrNull?.iaActiva ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MascotaOtto(tamano: 44),
              const SizedBox(width: 8),
              Text('Otto dice:', style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          if (devolucion.isLoading)
            Row(
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: TemaApp.verde)),
                const SizedBox(width: 10),
                Text('Analizando tu mes…', style: TextStyle(color: context.colores.textoSecundario)),
              ],
            )
          else
            Text(
              devolucion.valueOrNull ??
                  (iaActiva
                      ? 'No pude generar la devolución ahora. Revisá tu conexión e intentá de nuevo.'
                      : 'La IA está apagada. Se activa en Menú → Privacidad y seguridad.'),
              style: TextStyle(color: context.colores.textoSecundario, height: 1.4),
            ),
        ],
      ),
    );
  }
}

/// Capitaliza la primera letra del nombre del mes.
String capitalizarMes(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
