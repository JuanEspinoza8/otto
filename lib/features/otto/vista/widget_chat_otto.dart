import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/ui/widgets/mascota_otto.dart';
import '../logica/otto_provider.dart';
import 'tarjeta_propuesta.dart';

/// Chat "Decile a Otto": gastos e ingresos en lenguaje natural (uno o varios
/// por frase), que se confirman de a uno.
class WidgetChatOtto extends ConsumerStatefulWidget {
  const WidgetChatOtto({super.key});

  @override
  ConsumerState<WidgetChatOtto> createState() => _WidgetChatOttoState();
}

class _WidgetChatOttoState extends ConsumerState<WidgetChatOtto> {
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _texto.text.trim();
    // Enter respeta lo mismo que el botón: nada mientras procesa.
    if (texto.isEmpty || ref.read(ottoControladorProvider).estado == EstadoOtto.procesando) return;
    ref.read(ottoControladorProvider.notifier).procesarMensaje(texto);
    _texto.clear();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(ottoControladorProvider);
    final procesando = estado.estado == EstadoOtto.procesando;

    return Container(
      padding: const EdgeInsets.all(20),
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
              const MascotaOtto(tamano: 64, cara: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text('DECILE A OTTO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colores.textoSecundario, letterSpacing: 1.1)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: context.colores.superficieAlta, borderRadius: BorderRadius.circular(20)),
                child: Text('Contale tus gastos 💬', style: TextStyle(fontSize: 9, color: context.colores.textoSecundario)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (estado.estado == EstadoOtto.sugerencia)
            for (final p in estado.propuestas) TarjetaPropuesta(key: ValueKey(p.id), propuesta: p),
          if (estado.estado == EstadoOtto.error)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: TemaApp.rojo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Text('😕', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(estado.mensajeError ?? 'No pude entender el mensaje',
                        style: const TextStyle(fontSize: 12, color: TemaApp.rojo)),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _texto,
                  onSubmitted: (_) => _enviar(),
                  style: TextStyle(color: context.colores.textoPrimario),
                  decoration: InputDecoration(
                    hintText: 'Ej: "pagué 50mil de luz y el super 12 lucas"',
                    hintMaxLines: 2,
                    hintStyle: TextStyle(fontSize: 12, color: context.colores.textoSecundario),
                    filled: true,
                    fillColor: context.colores.superficieAlta,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(color: TemaApp.verde, borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  tooltip: 'Enviar',
                  icon: procesando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: procesando ? null : _enviar,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
