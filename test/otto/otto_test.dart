import 'package:otto/core/dinero/dinero.dart';
import 'package:otto/core/libro/consultas_libro.dart';
import 'package:otto/core/libro/libro_providers.dart';
import 'package:otto/core/utilidades/fechas.dart';
import 'package:otto/features/categorias/modelo/categoria.dart';
import 'package:otto/features/categorias/repositorio/categoria_repositorio.dart';
import 'package:otto/features/configuracion/logica/ajustes_provider.dart';
import 'package:otto/features/otto/logica/interprete_ia.dart';
import 'package:otto/features/otto/logica/otto_provider.dart';
import 'package:otto/features/otto/logica/parser_local.dart';
import 'package:otto/features/recurrentes/logica/servicio_planes.dart';
import 'package:otto/features/recurrentes/modelo/plan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../soporte/base_v9.dart';

Dinero pesos(num p) => Dinero.desdeUnidades(p);

class _SinIa extends AjustesControlador {
  @override
  Future<Ajustes> build() async => const Ajustes(
        biometriaActiva: false,
        recordatorioDiario: false,
        horariosRecordatorios: [],
        nombreUsuario: '',
        salarioMensual: Dinero.cero(),
        valorHoraExtra: Dinero.cero(),
        iaActiva: false,
        bannerRecordatorioOculto: true,
      );
}

void main() {
  late Database db;
  late List<Categoria> categorias;

  setUp(() async {
    db = await abrirBaseNueva();
    categorias = await CategoriaRepositorio(db).todas();
  });
  tearDown(() => db.close());

  group('parser local', () {
    test('montos coloquiales', () {
      expect(ParserLocal.extraerMonto('1.5 lucas de verdulería'), pesos(1500));
      expect(ParserLocal.extraerMonto('pagué 2 cuotas de 15000'), pesos(15000));
      expect(ParserLocal.extraerMonto(r'gasté $3.500,50 en el super'), Dinero.parsear('3.500,50'));
      expect(ParserLocal.extraerMonto('compré 3 kilos por 2 mil'), pesos(2000));
    });

    test('tipo y categoría del mismo tipo', () {
      final s = ParserLocal.interpretar('cobré el sueldo 850 lucas', categorias).single;
      expect(s.tipo, 'ingreso');
      expect(categorias.firstWhere((c) => c.id == s.categoriaId).nombre, 'Sueldo');

      final g = ParserLocal.interpretar('pagué el sueldo de la niñera 50 mil', categorias).single;
      expect(g.tipo, 'gasto');
      expect(categorias.where((c) => c.id == g.categoriaId && c.tipo == 'ingreso'), isEmpty);
    });

    test('varios movimientos en una frase', () {
      final s = ParserLocal.interpretar('nafta 30 lucas y el super 12.500', categorias);
      expect(s.map((x) => x.monto), [pesos(30000), pesos(12500)]);
    });

    test('horas extra', () {
      final s = ParserLocal.interpretar('hice 3 horas extra', categorias).single;
      expect(s.tipo, 'ingreso');
      expect(s.horas, 3);
    });
  });

  test('un monto de la IA como texto pasa por el parser es_AR', () {
    final super_ = categorias.firstWhere((c) => c.nombre == 'Alimentación');
    final sugerencias = InterpreteIa.leerRespuesta(
      '```json\n{"movimientos":[{"tipo":"gasto","monto":"50.000","categoriaId":${super_.id},"descripcion":"Super"},'
      '{"tipo":"ingreso","monto":1500.5,"categoriaId":${super_.id},"descripcion":"x"},'
      '{"tipo":"gasto","monto":"","descripcion":"sin monto"}]}\n```',
      categorias,
    );
    expect(sugerencias.map((s) => s.monto), [pesos(50000), pesos(1500.5)]);
    // Una categoría de otro tipo se descarta.
    expect(sugerencias.last.categoriaId, isNull);
  });

  group('chat con fijos', () {
    late ProviderContainer c;
    late int netflix;

    setUp(() async {
      final servicios = categorias.firstWhere((c) => c.nombre == 'Servicios').id;
      final hoy = Periodo.de(DateTime.now());
      netflix = await ServicioPlanes(db).crear(Plan(
        tipo: TipoPlan.fijo, nombre: 'Netflix', categoriaId: servicios, monto: pesos(8000), primerPeriodo: hoy));
      await ServicioPlanes(db).crear(Plan(
        tipo: TipoPlan.fijo, nombre: 'Gas', categoriaId: servicios, monto: pesos(12000), primerPeriodo: hoy));
      c = ProviderContainer(overrides: [
        baseDatosProvider.overrideWith((ref) async => db),
        ajustesControladorProvider.overrideWith(_SinIa.new),
      ]);
      c.listen(ottoControladorProvider, (_, __) {});
    });
    tearDown(() => c.dispose());

    Future<List<PropuestaOtto>> decir(String texto) async {
      await c.read(ottoControladorProvider.notifier).procesarMensaje(texto);
      return c.read(ottoControladorProvider).propuestas;
    }

    test('solo concilia por nombre exacto', () async {
      expect((await decir('fui al cine 8 lucas')).single.fijo, isNull);
      expect((await decir('gaseosa 2000')).single.fijo, isNull);
      expect((await decir('netflix 9000')).single.fijo?.nombre, 'Netflix');
    });

    test('confirmar no toca el fijo salvo que se pida', () async {
      final p = (await decir('netflix 9000')).single;
      await c.read(ottoControladorProvider.notifier).confirmar(p);

      var plan = await ServicioPlanes(db).plan(netflix);
      expect(plan.periodosAplicados, isEmpty);
      expect(plan.monto, pesos(8000));

      final p2 = (await decir('netflix 9000')).single;
      await c.read(ottoControladorProvider.notifier).confirmar(p2, conciliarConFijo: true);
      plan = await ServicioPlanes(db).plan(netflix);
      expect(plan.periodosAplicados, {Periodo.de(DateTime.now())});
      expect(plan.monto, pesos(8000));

      final gastos = await ConsultasLibro(db).totalesMes(Periodo.de(DateTime.now()));
      expect(gastos.gastos, pesos(18000));
      expect(c.read(ottoControladorProvider).propuestas, isEmpty);
    });
  });
}
