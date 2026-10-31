import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/libro/libro_providers.dart';
import '../../../core/libro/modelo/meta.dart';
import '../../../core/libro/modelo/movimiento.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../../categorias/modelo/categoria.dart';
import '../../categorias/vista/dialogo_nueva_categoria.dart';
import '../../configuracion/logica/ajustes_provider.dart';
import '../../panel_control/logica/metas_provider.dart';
import '../../panel_control/vista/dialogo_nueva_meta.dart';
import '../../recurrentes/logica/horas_extras_provider.dart';
import '../../recurrentes/vista/dialogo_pagar_cuotas.dart';
import '../logica/mes_seleccionado_provider.dart';
import '../logica/movimientos_provider.dart';
import 'formulario/campo_monto.dart';
import 'formulario/mosaicos.dart';
import 'formulario/selector_tipo.dart';

/// Formulario para registrar un gasto, un ingreso o un aporte a una meta.
class FormularioMovimiento extends ConsumerStatefulWidget {
  const FormularioMovimiento({super.key});

  @override
  ConsumerState<FormularioMovimiento> createState() => _FormularioMovimientoState();
}

class _FormularioMovimientoState extends ConsumerState<FormularioMovimiento> {
  final _concepto = TextEditingController();
  final _monto = TextEditingController();
  TipoFormulario _tipo = TipoFormulario.gasto;
  DateTime _fecha = DateTime.now();
  Categoria? _categoria;
  Meta? _meta;
  bool _guardando = false;

  bool get _esHorasExtras => _tipo == TipoFormulario.ingreso && _categoria?.nombre == categoriaHorasExtras;

  @override
  void dispose() {
    _concepto.dispose();
    _monto.dispose();
    super.dispose();
  }

  void _avisar(String texto, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto, style: color == null ? null : const TextStyle(color: Colors.white)),
      backgroundColor: color,
    ));
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      if (_tipo == TipoFormulario.ahorro) {
        await _guardarAporte();
      } else if (_esHorasExtras) {
        await _guardarHorasExtras();
      } else {
        await _guardarIngresoOGasto();
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _guardarAporte() async {
    final meta = _meta;
    final pesos = Dinero.parsear(_monto.text);
    if (pesos == null || !pesos.esPositivo) return _avisar('Ingresá un monto válido');
    if (meta == null) return _avisar('Elegí una meta de ahorro');
    final ok = await ejecutarConAviso(context, () => ref.read(metasControladorProvider.notifier).aportar(meta, pesos));
    if (!ok || !mounted) return;
    _limpiar();
    _avisar('💰 Aportaste ${pesos.formatear()} a "${meta.nombre}"', TemaApp.verde);
  }

  Future<void> _guardarHorasExtras() async {
    final horas = (parsearCentesimos(_monto.text) ?? 0) / 100;
    if (horas <= 0) return _avisar('Ingresá la cantidad de horas');
    final ok = await ejecutarConAviso(
      context,
      () => ref.read(horasExtrasMesProvider.notifier).registrarHoras(horas, fecha: _fecha, descripcion: _concepto.text),
    );
    if (ok && mounted) _terminar(gastoSinSaldo: false);
  }

  Future<void> _guardarIngresoOGasto() async {
    final monto = Dinero.parsear(_monto.text);
    final categoria = _categoria;
    if (monto == null || !monto.esPositivo) return _avisar('Ingresá un monto válido');
    if (categoria == null) return _avisar('Elegí una categoría');

    final esGasto = _tipo == TipoFormulario.gasto;
    final disponible = await ref.read(disponibleProvider.future);
    if (!mounted) return;
    final ok = await ejecutarConAviso(
      context,
      () => ref.read(movimientosControladorProvider.notifier).registrar(
            tipo: esGasto ? TipoMovimiento.gasto : TipoMovimiento.ingreso,
            monto: monto,
            categoriaId: categoria.id!,
            fecha: _fecha,
            descripcion: _concepto.text,
          ),
    );
    // Un gasto que supera el disponible se registra igual (ya ocurrió), pero se avisa.
    if (ok && mounted) _terminar(gastoSinSaldo: esGasto && monto > disponible);
  }

  void _terminar({required bool gastoSinSaldo}) {
    final fecha = _fecha;
    _limpiar();
    final mesVisto = ref.read(mesSeleccionadoProvider);
    if (gastoSinSaldo) {
      _avisar('Gasto registrado. Ojo: quedás con saldo negativo.', TemaApp.rojo);
    } else if (fecha.year != mesVisto.year || fecha.month != mesVisto.month) {
      _avisar('Guardado en ${DateFormat('MMMM', 'es').format(fecha)}. Cambiá de mes para verlo.', TemaApp.azul);
    } else {
      _avisar('Movimiento guardado', TemaApp.verde);
    }
  }

  void _limpiar() {
    _concepto.clear();
    _monto.clear();
    setState(() {
      _categoria = null;
      _meta = null;
    });
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  /// Crea una categoría del tipo actual y la deja elegida.
  Future<void> _crearCategoria() async {
    final id = await DialogoNuevaCategoria.mostrar(context, _tipo == TipoFormulario.ingreso ? 'ingreso' : 'gasto');
    if (id == null) return;
    final categorias = await ref.read(categoriasControladorProvider.future);
    if (!mounted) return;
    setState(() => _categoria = categorias.where((c) => c.id == id).firstOrNull);
  }

  @override
  Widget build(BuildContext context) {
    final categorias = (ref.watch(categoriasControladorProvider).valueOrNull ?? const <Categoria>[])
        .where((c) => c.tipo == (_tipo == TipoFormulario.ingreso ? 'ingreso' : 'gasto'))
        .toList();
    final valorHora = ref.watch(ajustesControladorProvider).valueOrNull?.valorHoraExtra ?? const Dinero.cero();
    final etiqueta = TextStyle(fontSize: 12, color: context.colores.textoSecundario, fontWeight: FontWeight.bold, letterSpacing: 1.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectorTipo(
          actual: _tipo,
          alCambiar: (tipo) => setState(() {
            _tipo = tipo;
            _categoria = null;
          }),
        ),
        const SizedBox(height: 24),
        CampoMonto(
          controlador: _monto,
          alCambiar: () => setState(() {}),
          modoHoras: _esHorasExtras,
          valorHora: valorHora,
        ),
        const SizedBox(height: 24),
        Text(_tipo == TipoFormulario.ahorro ? 'META DE AHORRO' : 'CATEGORÍA', style: etiqueta),
        const SizedBox(height: 12),
        if (_tipo == TipoFormulario.ahorro)
          SelectorMetas(
            metas: ref.watch(metasControladorProvider).valueOrNull ?? const [],
            seleccionada: _meta,
            alElegir: (meta) => setState(() => _meta = meta),
            alCrear: () => DialogoNuevaMeta.mostrar(context),
          )
        else
          GrillaCategorias(
            categorias: categorias,
            seleccionada: _categoria,
            alElegir: (cat) => setState(() => _categoria = cat),
            alCrear: _crearCategoria,
            alPagarCuotas: _tipo == TipoFormulario.gasto ? () => DialogoPagarCuotas.mostrar(context) : null,
          ),
        const SizedBox(height: 24),
        // El aporte a una meta va con la fecha de hoy y un concepto automático.
        if (_tipo != TipoFormulario.ahorro) ...[
          Text('CONCEPTO', style: etiqueta),
          const SizedBox(height: 8),
          TextField(
            controller: _concepto,
            style: TextStyle(color: context.colores.textoPrimario),
            decoration: InputDecoration(
              hintText: 'Ej: almuerzo en el trabajo',
              hintStyle: TextStyle(color: context.colores.textoSecundario, fontSize: 14),
              filled: true,
              fillColor: context.colores.superficie,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          Text('FECHA', style: etiqueta),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _elegirFecha,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(color: context.colores.superficie, borderRadius: BorderRadius.circular(12)),
              child: Text(
                DateFormat("dd 'de' MMMM, yyyy", 'es').format(_fecha),
                style: TextStyle(fontSize: 14, color: context.colores.textoPrimario),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ] else
          const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: TemaApp.verde,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            switch (_tipo) {
              TipoFormulario.gasto => 'Registrar gasto',
              TipoFormulario.ingreso => 'Registrar ingreso',
              TipoFormulario.ahorro => 'Registrar ahorro',
            },
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
