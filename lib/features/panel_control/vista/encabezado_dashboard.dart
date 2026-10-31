import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/libro/consultas_libro.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../../../core/utilidades/texto.dart';
import '../../configuracion/logica/ajustes_provider.dart';
import '../logica/dashboard_provider.dart';
import 'widget_dolar_blue.dart';

/// Frase debajo del saludo, según cómo viene el mes.
String fraseDelMes(TotalesMes totales) {
  if (totales.vacio) return 'Todavía no cargaste movimientos este mes.';
  final resultado = totales.resultado;
  if (resultado.esNegativo) return 'Este mes gastaste ${(-resultado).formatear()} más de lo que entró.';
  if (totales.porcentajeAhorro >= 20) {
    return '¡Vas muy bien! Te queda el ${totales.porcentajeAhorro.floor()}% de lo que entró.';
  }
  return 'Este mes te quedan ${resultado.formatear()} de lo que entró.';
}

String _saludo(DateTime ahora) {
  if (ahora.hour < 12) return 'Buenos días';
  if (ahora.hour < 20) return 'Buenas tardes';
  return 'Buenas noches';
}

/// Saludo con el nombre, la frase del mes y el blue.
class EncabezadoDashboard extends ConsumerWidget {
  const EncabezadoDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = ref.watch(ajustesControladorProvider).valueOrNull?.nombreUsuario ?? '';
    final totales = ref.watch(totalesMesProvider).valueOrNull;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_saludo(DateTime.now())}${nombre.isEmpty ? '' : ', ${capitalizar(nombre)}'} 👋',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.colores.textoPrimario),
              ),
              if (totales != null) ...[
                const SizedBox(height: 4),
                Text(fraseDelMes(totales), style: TextStyle(color: context.colores.textoSecundario, fontSize: 12)),
              ],
            ],
          ),
        ),
        const WidgetDolarBlue(),
      ],
    );
  }
}

/// Ofrece activar el recordatorio diario hasta que se active o se descarte.
class BannerRecordatorio extends ConsumerWidget {
  const BannerRecordatorio({super.key});

  Future<void> _activar(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(ajustesControladorProvider.notifier);
    final horarios = ref.read(ajustesControladorProvider).valueOrNull?.horariosRecordatorios ?? const ['20:00'];
    final ok = await ejecutarConAviso(
      context,
      notifier.activarRecordatorioDiario,
      exito: '🔔 Te recuerdo a las ${horarios.join(' y ')}. Podés cambiar el horario en Menú.',
    );
    if (ok) await notifier.ocultarBannerRecordatorio();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ajustes = ref.watch(ajustesControladorProvider).valueOrNull;
    if (ajustes == null || ajustes.recordatorioDiario || ajustes.bannerRecordatorioOculto) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colores.superficie,
        border: Border.all(color: TemaApp.verde.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤔', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('¿Querés que te recuerde cargar tus gastos?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.colores.textoPrimario)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Otto te manda un recordatorio cada noche para que no pierdas el control de tu plata.',
              style: TextStyle(fontSize: 12, color: context.colores.textoSecundario)),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _activar(context, ref),
                style: ElevatedButton.styleFrom(backgroundColor: TemaApp.verde, foregroundColor: Colors.white, elevation: 0),
                child: const Text('Activar recordatorios', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: ref.read(ajustesControladorProvider.notifier).ocultarBannerRecordatorio,
                child: Text('Ahora no', style: TextStyle(color: context.colores.textoSecundario)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
