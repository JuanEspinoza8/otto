import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/libro/libro_providers.dart';
import '../modelo/categoria.dart';
import '../repositorio/categoria_repositorio.dart';

part 'categorias_provider.g.dart';

@riverpod
class CategoriasControlador extends _$CategoriasControlador {
  @override
  Future<List<Categoria>> build() async {
    ref.watch(versionDatosProvider);
    return CategoriaRepositorio(await ref.watch(baseDatosProvider.future)).todas();
  }

  /// Crea la categoría y devuelve su id.
  Future<int> agregar(Categoria categoria) =>
      escribirEnTransaccion(ref, (txn) => CategoriaRepositorio(txn).insertar(categoria));

  Future<void> actualizar(Categoria categoria) =>
      escribirEnTransaccion(ref, (txn) => CategoriaRepositorio(txn).actualizar(categoria));

  Future<int> usos(Categoria categoria) async =>
      CategoriaRepositorio(await ref.read(baseDatosProvider.future)).usos(categoria.id!);

  /// Borra la categoría; sus movimientos y planes pasan a [reasignarA].
  Future<void> eliminar(Categoria categoria, {int? reasignarA}) => escribirEnTransaccion(
      ref, (txn) => CategoriaRepositorio(txn).eliminar(categoria.id!, reasignarA: reasignarA));
}
