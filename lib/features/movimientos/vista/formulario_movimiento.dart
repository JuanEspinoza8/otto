import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/tema/tema_app.dart';
import '../../../core/utilidades/mapeador_iconos.dart';
import '../../categorias/logica/categorias_provider.dart';
import '../../categorias/modelo/categoria.dart';
import '../../categorias/vista/dialogo_nueva_categoria.dart';
import '../../panel_control/logica/metas_provider.dart';
import '../../panel_control/logica/ahorro_disponible_provider.dart';
import '../../panel_control/logica/ahorros_provider.dart';
import '../../panel_control/logica/dashboard_provider.dart';
import '../../panel_control/logica/dolar_blue_provider.dart';
import '../../panel_control/modelo/meta.dart';
import '../../panel_control/vista/dialogo_nueva_meta.dart';
import '../../configuracion/logica/ajustes_provider.dart';
import '../../recurrentes/vista/dialogo_pagar_cuotas.dart';
import '../../recurrentes/logica/horas_extras_provider.dart';
import '../modelo/movimiento.dart';
import '../logica/movimientos_provider.dart';
import '../logica/mes_seleccionado_provider.dart';
import '../../../core/dinero/dinero.dart';
import '../../../core/dinero/formateador_monto.dart';

class FormularioMovimiento extends ConsumerStatefulWidget {
  const FormularioMovimiento({super.key});

  @override
  ConsumerState<FormularioMovimiento> createState() => _FormularioMovimientoState();
}

class _FormularioMovimientoState extends ConsumerState<FormularioMovimiento> {
  final _claveFormulario = GlobalKey<FormState>();
  String _tipoActual = 'gasto'; // 'ingreso', 'gasto', 'ahorro'
  final _controladorConcepto = TextEditingController();
  final _controladorMonto = TextEditingController();
  DateTime _fechaActual = DateTime.now();
  Categoria? _categoriaSeleccionada;
  Meta? _metaSeleccionada;

  @override
  void dispose() {
    _controladorConcepto.dispose();
    _controladorMonto.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaActual,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (seleccionada != null && seleccionada != _fechaActual) {
      setState(() {
        _fechaActual = seleccionada;
      });
    }
  }

  void _guardarMovimiento() {
    if (_controladorMonto.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un monto válido')));
       return;
    }
    // En modo "horas extras" el número son horas (con decimales); si no, es un
    // monto. Ambos se interpretan con el mismo parser es_AR.
    final monto = (parsearCentesimos(_controladorMonto.text) ?? 0) / 100;
    if (monto <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un monto válido')));
       return;
    }

    // Caso especial: el tab "Ahorro" aporta a una meta de ahorro.
    if (_tipoActual == 'ahorro') {
      if (_metaSeleccionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Elegí una meta de ahorro')));
        return;
      }
      // Sólo validamos el tope si los datos del disponible ya cargaron; si no,
      // el número sería parcial (sin el ahorro previo) y daría un valor errado.
      final datosListos = ref.read(ahorrosControladorProvider).hasValue && ref.read(totalesGlobalesProvider).hasValue;
      final disponible = ref.read(ahorroDisponibleProvider);
      if (datosListos && monto > disponible + 0.5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No te alcanza. Disponible: ${Dinero.desdeUnidades(disponible).formatear()}')),
        );
        return;
      }
      final blue = ref.read(dolarBlueProvider).valueOrNull?['venta'] ?? 0.0;
      if (_metaSeleccionada!.esUsd && blue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esperá a que cargue la cotización del dólar')),
        );
        return;
      }
      ref.read(metasControladorProvider.notifier).aportar(_metaSeleccionada!, monto, blue: blue);
      _controladorConcepto.clear();
      _controladorMonto.clear();
      final nombreMeta = _metaSeleccionada!.nombre;
      setState(() => _metaSeleccionada = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('💰 Aportaste a "$nombreMeta"', style: const TextStyle(color: Colors.white)), backgroundColor: TemaApp.verde),
      );
      return;
    }

    if (_categoriaSeleccionada == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione una categoría')));
       return;
    }

    // Aviso NO bloqueante: si el gasto supera la plata libre, igual lo
    // registramos (es un gasto real que ya pasó), pero avisamos que el
    // disponible queda en negativo. Cuotas/fijos van por otro flujo.
    bool gastoDejaSaldoNegativo = false;
    if (_tipoActual == 'gasto' && ref.read(totalesGlobalesProvider).hasValue) {
      final disponible = ref.read(ahorroDisponibleProvider);
      gastoDejaSaldoNegativo = monto > disponible + 0.5;
    }

    // Caso especial: categoría "Horas extras" → el número son horas y se
    // multiplica por el valor de la hora extra configurado.
    double montoFinal = monto;
    String? descripcionAuto;
    final esHorasExtras = _tipoActual == 'ingreso' && _categoriaSeleccionada!.nombre == 'Horas extras';
    if (esHorasExtras) {
      final valor = (ref.read(ajustesControladorProvider).valueOrNull?['valorHoraExtra'] as double?) ?? 0;
      if (valor <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configurá el valor de la hora extra en Menú')));
        return;
      }
      montoFinal = monto * valor; // monto = cantidad de horas
      final horasTxt = monto % 1 == 0 ? monto.toStringAsFixed(0) : monto.toString();
      descripcionAuto = '$horasTxt horas extra';
    }

    if (_claveFormulario.currentState!.validate()) {
      final nuevoMovimiento = Movimiento(
        monto: montoFinal,
        fecha: _fechaActual,
        descripcion: _controladorConcepto.text.isEmpty ? descripcionAuto : _controladorConcepto.text,
        tipo: _tipoActual,
        categoriaId: _categoriaSeleccionada!.id!,
      );

      ref.read(movimientosControladorProvider.notifier).agregarMovimiento(nuevoMovimiento);

      // Si cargó horas extra de este mes por el formulario, marcamos la
      // pregunta mensual como resuelta para no contarlas dos veces.
      final ahora = DateTime.now();
      if (esHorasExtras && _fechaActual.year == ahora.year && _fechaActual.month == ahora.month) {
        ref.read(horasExtrasMesProvider.notifier).marcarResuelto();
      }

      _controladorConcepto.clear();
      _controladorMonto.clear();
      setState(() {
        _categoriaSeleccionada = null;
      });

      // Mensaje final: avisa si quedó con saldo negativo o si quedó guardado en
      // un mes distinto al que estás viendo (para que no "desaparezca").
      final mesSel = ref.read(mesSeleccionadoProvider);
      final otroMes = _fechaActual.year != mesSel.year || _fechaActual.month != mesSel.month;
      final String mensaje;
      final Color colorMsg;
      if (gastoDejaSaldoNegativo) {
        mensaje = 'Gasto registrado. Ojo: quedás con saldo negativo.';
        colorMsg = TemaApp.rojo;
      } else if (otroMes) {
        mensaje = 'Guardado en ${DateFormat('MMMM', 'es').format(_fechaActual)}. Cambiá de mes para verlo.';
        colorMsg = TemaApp.azul;
      } else {
        mensaje = 'Movimiento guardado exitosamente';
        colorMsg = TemaApp.verde;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje, style: const TextStyle(color: Colors.white)), backgroundColor: colorMsg),
      );
    }
  }

  /// Abre el diálogo para crear una categoría del tipo actual y, si se crea,
  /// la deja seleccionada.
  Future<void> _crearCategoria() async {
    final nombre = await DialogoNuevaCategoria.mostrar(context, _tipoActual);
    if (nombre == null) return;
    final cats = ref.read(categoriasControladorProvider).valueOrNull ?? [];
    final nuevas = cats.where((c) => c.nombre == nombre && c.tipo == _tipoActual);
    if (nuevas.isNotEmpty) {
      setState(() => _categoriaSeleccionada = nuevas.last);
    }
  }

  /// Selector de metas para el modo "Ahorro": elegís a qué meta aportar.
  Widget _construirSelectorMetas(BuildContext context) {
    final metas = (ref.watch(metasControladorProvider).valueOrNull ?? {}).keys.toList();
    final anchoTile = (MediaQuery.of(context).size.width - 32 - 36) / 4;

    if (metas.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colores.superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colores.borde),
        ),
        child: Column(
          children: [
            Text('Todavía no tenés metas de ahorro', style: TextStyle(color: context.colores.textoSecundario)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => DialogoNuevaMeta.mostrar(context),
              icon: const Icon(Icons.add, color: TemaApp.verde),
              label: const Text('Crear meta', style: TextStyle(color: TemaApp.verde, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ...metas.map((meta) {
          final sel = _metaSeleccionada?.id == meta.id;
          return GestureDetector(
            onTap: () => setState(() => _metaSeleccionada = meta),
            child: Container(
              width: anchoTile,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: sel ? TemaApp.azul.withValues(alpha: 0.15) : context.colores.superficie,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? TemaApp.azul : context.colores.borde, width: sel ? 2 : 1),
              ),
              child: Column(
                children: [
                  Icon(MapeadorIconos.obtenerIcono(meta.icono), color: TemaApp.azul),
                  const SizedBox(height: 8),
                  Text(
                    meta.nombre,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.normal, color: sel ? TemaApp.azul : context.colores.textoPrimario),
                  ),
                  Text('${meta.porcentajeProgreso.toInt()}%', style: TextStyle(fontSize: 9, color: context.colores.textoSecundario)),
                ],
              ),
            ),
          );
        }),
        GestureDetector(
          onTap: () => DialogoNuevaMeta.mostrar(context),
          child: Container(
            width: anchoTile,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: TemaApp.verde.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TemaApp.verde, width: 1),
            ),
            child: const Column(
              children: [
                Icon(Icons.add, color: TemaApp.verde),
                SizedBox(height: 8),
                Text('Meta', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TemaApp.verde)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriasControladorProvider);
    final categorias = categoriasAsync.valueOrNull ?? [];
    final categoriasFiltradas = categorias.where((c) => c.tipo == _tipoActual).toList();
    // Mantiene cargados los totales y el ahorro previo para que el bloqueo/aviso
    // de saldo sea confiable apenas se abre el formulario (evita leer el
    // disponible con datos a medio cargar, que daba un número equivocado).
    ref.watch(totalesGlobalesProvider);
    ref.watch(ahorrosControladorProvider);

    // Modo "horas extras": el visor cuenta horas y se calcula el total con el
    // valor de la hora extra configurado en el perfil.
    final ajustes = ref.watch(ajustesControladorProvider).valueOrNull ?? const {};
    final valorHoraExtra = (ajustes['valorHoraExtra'] as double?) ?? 0.0;
    final esHorasExtras = _tipoActual == 'ingreso' && _categoriaSeleccionada?.nombre == 'Horas extras';
    final horasIngresadas = (parsearCentesimos(_controladorMonto.text) ?? 0) / 100;
    final totalHorasExtras = horasIngresadas * valorHoraExtra;

    return Form(
      key: _claveFormulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selector de Tipo
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.colores.superficie,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(child: _BotonTipo(titulo: '💸 Gasto', activo: _tipoActual == 'gasto', colorActivo: TemaApp.rojo, alPresionar: () => setState(() { _tipoActual = 'gasto'; _categoriaSeleccionada = null; }))),
                Expanded(child: _BotonTipo(titulo: '💰 Ingreso', activo: _tipoActual == 'ingreso', colorActivo: TemaApp.verde, alPresionar: () => setState(() { _tipoActual = 'ingreso'; _categoriaSeleccionada = null; }))),
                Expanded(child: _BotonTipo(titulo: '🏦 Ahorro', activo: _tipoActual == 'ahorro', colorActivo: TemaApp.azul, alPresionar: () => setState(() { _tipoActual = 'ahorro'; _categoriaSeleccionada = null; }))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Cuadro de MONTO (se adapta al tema claro/oscuro)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: context.colores.superficie,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.colores.borde),
            ),
            child: Column(
              children: [
                Text(esHorasExtras ? 'CANTIDAD DE HORAS' : 'MONTO', style: TextStyle(color: context.colores.textoSecundario, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!esHorasExtras)
                      Text('\$', style: TextStyle(color: context.colores.textoPrimario, fontSize: 48, fontWeight: FontWeight.bold)),
                    IntrinsicWidth(
                      child: TextField(
                        controller: _controladorMonto,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: esHorasExtras
                            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*'))]
                            : [FormateadorMonto()],
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: context.colores.textoPrimario, fontSize: 56, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: context.colores.textoSecundario),
                          filled: false,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (esHorasExtras)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text('hs', style: TextStyle(color: context.colores.textoSecundario, fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                if (esHorasExtras) ...[
                  const SizedBox(height: 8),
                  Text(
                    valorHoraExtra > 0
                        ? '= ${Dinero.desdeUnidades(totalHorasExtras).formatear()}  (a ${Dinero.desdeUnidades(valorHoraExtra).formatear()}/h)'
                        : 'Configurá el valor de la hora extra en Menú',
                    style: const TextStyle(color: TemaApp.verde, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Categorías (Grid) o selector de meta si es ahorro
          Text(_tipoActual == 'ahorro' ? 'META DE AHORRO' : 'CATEGORÍA', style: TextStyle(fontSize: 12, color: context.colores.textoSecundario, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 12),
          if (_tipoActual == 'ahorro')
            _construirSelectorMetas(context)
          else
            Builder(builder: (context) {
              final anchoTile = (MediaQuery.of(context).size.width - 32 - 36) / 4;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...categoriasFiltradas.map((cat) {
                    final esSeleccionada = _categoriaSeleccionada?.id == cat.id;
                    final colorCat = Color(int.parse(cat.colorHex));
                    return GestureDetector(
                      onTap: () => setState(() => _categoriaSeleccionada = cat),
                      child: Container(
                        width: anchoTile,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        decoration: BoxDecoration(
                          color: esSeleccionada ? colorCat.withValues(alpha: 0.15) : context.colores.superficie,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: esSeleccionada ? colorCat : context.colores.borde,
                            width: esSeleccionada ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(MapeadorIconos.obtenerIcono(cat.icono), color: colorCat),
                            const SizedBox(height: 8),
                            Text(
                              cat.nombre,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: esSeleccionada ? FontWeight.bold : FontWeight.normal,
                                color: esSeleccionada ? colorCat : context.colores.textoPrimario,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  // Tile especial "Cuotas": abre el flujo de pago de cuotas.
                  if (_tipoActual == 'gasto')
                    GestureDetector(
                      onTap: () => DialogoPagarCuotas.mostrar(context),
                      child: Container(
                        width: anchoTile,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        decoration: BoxDecoration(
                          color: TemaApp.azul.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: TemaApp.azul, width: 1),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.credit_card, color: TemaApp.azul),
                            SizedBox(height: 8),
                            Text(
                              'Cuotas',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TemaApp.azul),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Tile para crear una nueva categoría
                  GestureDetector(
                    onTap: _crearCategoria,
                    child: Container(
                      width: anchoTile,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      decoration: BoxDecoration(
                        color: TemaApp.verde.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TemaApp.verde, width: 1),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.add, color: TemaApp.verde),
                          SizedBox(height: 8),
                          Text(
                            'Nueva',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TemaApp.verde),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          const SizedBox(height: 24),

          // Concepto y fecha: no aplican al mover plata a un fondo de ahorro
          // (el aporte va con la fecha de hoy y un concepto automático).
          if (_tipoActual != 'ahorro') ...[
            Text('CONCEPTO', style: TextStyle(fontSize: 12, color: context.colores.textoSecundario, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            TextField(
              controller: _controladorConcepto,
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
            Text('FECHA', style: TextStyle(fontSize: 12, color: context.colores.textoSecundario, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _seleccionarFecha(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: context.colores.superficie,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DateFormat('dd \'de\' MMMM, yyyy', 'es').format(_fechaActual),
                  style: TextStyle(fontSize: 14, color: context.colores.textoPrimario),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ] else
            const SizedBox(height: 8),

          // Boton
          ElevatedButton(
            onPressed: _guardarMovimiento,
            style: ElevatedButton.styleFrom(
              backgroundColor: TemaApp.verde,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              _tipoActual == 'gasto' ? 'Registrar gasto' : 
              _tipoActual == 'ingreso' ? 'Registrar ingreso' : 'Registrar ahorro',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonTipo extends StatelessWidget {
  final String titulo;
  final bool activo;
  final Color colorActivo;
  final VoidCallback alPresionar;

  const _BotonTipo({required this.titulo, required this.activo, required this.colorActivo, required this.alPresionar});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alPresionar,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: activo ? colorActivo : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          titulo,
          style: TextStyle(
            color: activo ? Colors.white : context.colores.textoSecundario,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
