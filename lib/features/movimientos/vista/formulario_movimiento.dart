import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/libro/consultas_libro.dart';
import '../../../core/libro/libro_providers.dart';
import '../../../core/libro/modelo/meta.dart';
import '../../../core/libro/modelo/movimiento.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/ui/acciones.dart';
import '../../../core/utilidades/fechas.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../../categorias/logica/presupuesto.dart';
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
import 'formulario/concepto_y_fecha.dart';
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
    if (!ok || !mounted) return;
    // Un gasto que supera el disponible se registra igual (ya ocurrió), pero
    // se avisa; también si con este gasto la categoría cruzó su presupuesto.
    final aviso = esGasto ? await _avisoPresupuesto(categoria, monto) : null;
    if (mounted) _terminar(gastoSinSaldo: esGasto && monto > disponible, avisoPresupuesto: aviso);
  }

  Future<String?> _avisoPresupuesto(Categoria categoria, Dinero monto) async {
    if (!categoria.presupuestoLimite.esPositivo) return null;
    final db = await ref.read(baseDatosProvider.future);
    final gastos = await ConsultasLibro(db).totalesPorCategoria(Periodo.de(_fecha), TipoMovimiento.gasto);
    final despues = gastos[categoria.id] ?? const Dinero.cero();
    return avisoPresupuesto(categoria.nombre, despues - monto, despues, categoria.presupuestoLimite);
  }

  void _terminar({required bool gastoSinSaldo, String? avisoPresupuesto}) {
    final fecha = _fecha;
    _limpiar();
    final mesVisto = ref.read(mesSeleccionadoProvider);
    if (avisoPresupuesto != null) {
      _avisar('Gasto registrado. $avisoPresupuesto.', avisoPresupuesto.startsWith('Te pasaste') ? TemaApp.rojo : TemaApp.amarillo);
    } else if (gastoSinSaldo) {
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
    // Mantiene cargado el disponible para el aviso de saldo negativo.
    ref.watch(disponibleProvider);
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
          ConceptoYFecha(concepto: _concepto, fecha: _fecha, alCambiarFecha: (f) => setState(() => _fecha = f)),
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
