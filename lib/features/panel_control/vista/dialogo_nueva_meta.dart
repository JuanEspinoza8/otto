import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/tema_app.dart';
import '../../../core/utilidades/mapeador_iconos.dart';
import '../../../core/utilidades/formateador_miles.dart';
import '../logica/metas_provider.dart';
import '../modelo/meta.dart';

/// Diálogo para crear una nueva meta de ahorro.
class DialogoNuevaMeta extends ConsumerStatefulWidget {
  final Meta? aEditar;
  const DialogoNuevaMeta({super.key, this.aEditar});

  /// Abre el diálogo de creación (o edición) de meta.
  static Future<void> mostrar(BuildContext context, {Meta? aEditar}) {
    return showDialog(
      context: context,
      builder: (_) => DialogoNuevaMeta(aEditar: aEditar),
    );
  }

  @override
  ConsumerState<DialogoNuevaMeta> createState() => _DialogoNuevaMetaState();
}

class _DialogoNuevaMetaState extends ConsumerState<DialogoNuevaMeta> {
  late final TextEditingController _controladorNombre;
  late final TextEditingController _controladorMonto;
  late String _icono;
  late String _moneda;
  bool _guardando = false;

  static const List<String> _iconos = [
    'flight', 'home', 'directions_car', 'school',
    'videogame_asset', 'fitness_center', 'pets', 'category',
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.aEditar;
    _controladorNombre = TextEditingController(text: m?.nombre ?? '');
    _controladorMonto = TextEditingController(text: montoEditable(m?.montoObjetivo ?? 0));
    _icono = m?.icono ?? 'flight';
    _moneda = m?.moneda ?? 'ARS';
  }

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorMonto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _controladorNombre.text.trim();
    final monto = double.tryParse(
          _controladorMonto.text.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0;

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá un nombre para la meta')),
      );
      return;
    }
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá un monto objetivo válido')),
      );
      return;
    }

    setState(() => _guardando = true);
    final controlador = ref.read(metasControladorProvider.notifier);
    final editar = widget.aEditar;
    if (editar != null) {
      await controlador.actualizarMeta(editar.copiaCon(
        nombre: nombre,
        montoObjetivo: monto,
        icono: _icono,
        moneda: _moneda,
      ));
    } else {
      await controlador.agregarMeta(Meta(
        nombre: nombre,
        montoObjetivo: monto,
        icono: _icono,
        moneda: _moneda,
        fechaCreacion: DateTime.now(),
      ));
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Si la meta ya tiene plata adentro, no se puede cambiar la moneda (el monto
    // guardado quedaría mal valuado).
    final puedeCambiarMoneda = widget.aEditar == null || widget.aEditar!.montoActual <= 0;
    return AlertDialog(
      backgroundColor: context.colores.superficie,
      title: Text(widget.aEditar == null ? 'Nueva meta de ahorro' : 'Editar meta', style: TextStyle(color: context.colores.textoPrimario, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controladorNombre,
              style: TextStyle(color: context.colores.textoPrimario),
              decoration: const InputDecoration(hintText: 'Ej: Viaje a Brasil'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controladorMonto,
              keyboardType: TextInputType.number,
              inputFormatters: [FormateadorMiles()],
              style: TextStyle(color: context.colores.textoPrimario),
              decoration: InputDecoration(prefixText: _moneda == 'USD' ? 'U\$D ' : '\$ ', hintText: 'Monto objetivo'),
            ),
            const SizedBox(height: 16),
            Text('Moneda', style: TextStyle(color: context.colores.textoSecundario, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _ChipMoneda(texto: 'Pesos (ARS)', activo: _moneda == 'ARS', onTap: puedeCambiarMoneda ? () => setState(() => _moneda = 'ARS') : null)),
                const SizedBox(width: 8),
                Expanded(child: _ChipMoneda(texto: 'Dólares (USD)', activo: _moneda == 'USD', onTap: puedeCambiarMoneda ? () => setState(() => _moneda = 'USD') : null)),
              ],
            ),
            const SizedBox(height: 20),
            Text('Ícono', style: TextStyle(color: context.colores.textoSecundario, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconos.map((nombre) {
                final seleccionado = _icono == nombre;
                return GestureDetector(
                  onTap: () => setState(() => _icono = nombre),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: seleccionado ? TemaApp.verde.withValues(alpha: 0.2) : context.colores.superficieAlta,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: seleccionado ? TemaApp.verde : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      MapeadorIconos.obtenerIcono(nombre),
                      color: seleccionado ? TemaApp.verde : context.colores.textoSecundario,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: context.colores.textoSecundario)),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(backgroundColor: TemaApp.verde, foregroundColor: Colors.white),
          child: _guardando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(widget.aEditar == null ? 'Crear meta' : 'Guardar'),
        ),
      ],
    );
  }
}

/// Botón tipo chip para elegir la moneda de la meta.
class _ChipMoneda extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback? onTap;
  const _ChipMoneda({required this.texto, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activo ? TemaApp.verde.withValues(alpha: 0.15) : context.colores.superficieAlta,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: activo ? TemaApp.verde : Colors.transparent, width: 2),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: activo ? TemaApp.verde : context.colores.textoSecundario,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
