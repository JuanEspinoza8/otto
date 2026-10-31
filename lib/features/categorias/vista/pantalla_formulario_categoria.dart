import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/dinero/dinero.dart';
import '../../../core/dinero/formateador_monto.dart';
import '../../../core/utilidades/mapeador_iconos.dart';
import '../logica/categorias_provider.dart';
import '../modelo/categoria.dart';
import '../../../core/ui/acciones.dart';
import 'dialogo_borrar_categoria.dart';

class PantallaFormularioCategoria extends ConsumerStatefulWidget {
  final Categoria? categoriaAEditar;

  const PantallaFormularioCategoria({super.key, this.categoriaAEditar});

  @override
  ConsumerState<PantallaFormularioCategoria> createState() => _PantallaFormularioCategoriaState();
}

class _PantallaFormularioCategoriaState extends ConsumerState<PantallaFormularioCategoria> {
  final _llaveFormulario = GlobalKey<FormState>();
  late String _nombre;
  late String _tipo;
  late String _colorHex;
  late String _icono;
  late Dinero _presupuestoLimite;

  /// Movimientos y planes que usan la categoría: con alguno, el tipo no se
  /// puede cambiar (ingresos pasarían a contarse como gastos).
  int _usos = 0;
  bool _guardando = false;

  final List<String> _colores = [
    '0xFFF44336', '0xFFE91E63', '0xFF9C27B0', '0xFF673AB7',
    '0xFF3F51B5', '0xFF2196F3', '0xFF03A9F4', '0xFF00BCD4',
    '0xFF009688', '0xFF4CAF50', '0xFF8BC34A', '0xFFCDDC39',
    '0xFFFFEB3B', '0xFFFFC107', '0xFFFF9800', '0xFFFF5722',
  ];

  @override
  void initState() {
    super.initState();
    final cat = widget.categoriaAEditar;
    _nombre = cat?.nombre ?? '';
    _tipo = cat?.tipo ?? 'gasto';
    _colorHex = cat?.colorHex ?? '0xFF2196F3';
    _icono = cat?.icono ?? 'category';
    _presupuestoLimite = cat?.presupuestoLimite ?? const Dinero.cero();
    if (cat != null) {
      ref.read(categoriasControladorProvider.notifier).usos(cat).then((n) {
        if (mounted) setState(() => _usos = n);
      });
    }
  }

  Future<void> _guardar() async {
    if (!_llaveFormulario.currentState!.validate()) return;
    _llaveFormulario.currentState!.save();
    final categoria = Categoria(
      id: widget.categoriaAEditar?.id,
      nombre: _nombre,
      tipo: _tipo,
      colorHex: _colorHex,
      icono: _icono,
      presupuestoLimite: _presupuestoLimite,
      esSistema: widget.categoriaAEditar?.esSistema ?? false,
    );
    final controlador = ref.read(categoriasControladorProvider.notifier);
    setState(() => _guardando = true);
    final ok = await ejecutarConAviso(
      context,
      () async => widget.categoriaAEditar == null ? await controlador.agregar(categoria) : await controlador.actualizar(categoria),
    );
    if (!mounted) return;
    ok ? Navigator.pop(context) : setState(() => _guardando = false);
  }

  Future<void> _eliminar() async {
    final borrada = await DialogoBorrarCategoria.mostrar(context, ref, widget.categoriaAEditar!);
    if (borrada && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.categoriaAEditar != null;
    final esSistema = widget.categoriaAEditar?.esSistema ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Categoría' : 'Nueva Categoría'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (esEdicion && !esSistema)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _eliminar,
              )
        ],
      ),
      body: Form(
        key: _llaveFormulario,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _ConstruirCaja(
              hijo: TextFormField(
                initialValue: _nombre,
                decoration: const InputDecoration(labelText: 'Nombre del rubro', border: InputBorder.none),
                validator: (valor) => (valor == null || valor.trim().isEmpty) ? 'Campo requerido' : null,
                onSaved: (valor) => _nombre = valor!.trim(),
                readOnly: esSistema,
              ),
            ),
            const SizedBox(height: 16),
            _ConstruirCaja(
              hijo: DropdownButtonFormField<String>(
                initialValue: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo Contable', border: InputBorder.none),
                items: const [
                  DropdownMenuItem(value: 'ingreso', child: Text('Ingreso')),
                  DropdownMenuItem(value: 'gasto', child: Text('Gasto')),
                ],
                onChanged: (esSistema || _usos > 0) ? null : (valor) { if (valor != null) setState(() => _tipo = valor); },
              ),
            ),
            const SizedBox(height: 16),
            _ConstruirCaja(
              hijo: TextFormField(
                initialValue: _presupuestoLimite.textoEditable,
                decoration: const InputDecoration(labelText: 'Presupuesto Límite (Opcional)', border: InputBorder.none),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FormateadorMonto()],
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) return null;
                  return Dinero.parsear(valor) == null ? 'Monto inválido' : null;
                },
                onSaved: (valor) => _presupuestoLimite = Dinero.parsear(valor ?? '') ?? const Dinero.cero(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Color Personalizado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colores.map((color) => GestureDetector(
                onTap: () => setState(() => _colorHex = color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color)),
                    shape: BoxShape.circle,
                    border: _colorHex == color ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: _colorHex == color ? [
                      BoxShadow(color: Color(int.parse(color)).withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)
                    ] : [],
                  ),
                  child: _colorHex == color ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Ícono Representativo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: MapeadorIconos.obtenerNombresDisponibles().map((nombreIcono) {
                final estaSeleccionado = _icono == nombreIcono;
                return GestureDetector(
                  onTap: () => setState(() => _icono = nombreIcono),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: estaSeleccionado ? Color(int.parse(_colorHex)).withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: estaSeleccionado ? Color(int.parse(_colorHex)) : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      MapeadorIconos.obtenerIcono(nombreIcono),
                      color: estaSeleccionado ? Color(int.parse(_colorHex)) : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(int.parse(_colorHex)),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              onPressed: _guardando ? null : _guardar,
              child: const Text('Guardar Categoría', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ConstruirCaja extends StatelessWidget {
  final Widget hijo;
  const _ConstruirCaja({required this.hijo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: hijo,
    );
  }
}
