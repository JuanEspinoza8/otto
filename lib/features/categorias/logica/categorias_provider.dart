import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../modelo/categoria.dart';
import '../repositorio/categoria_repositorio.dart';

// Es obligatorio generar este archivo ejecutando:
// flutter pub run build_runner build
part 'categorias_provider.g.dart';

@riverpod
class CategoriasControlador extends _$CategoriasControlador {
  final CategoriaRepositorio _repositorio = CategoriaRepositorio();

  @override
  FutureOr<List<Categoria>> build() async {
    return await _repositorio.obtenerTodas();
  }

  /// Agrega una nueva categoría e invalida el estado para forzar la recarga
  Future<void> agregarCategoria(Categoria categoria) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repositorio.insertar(categoria);
      return await _repositorio.obtenerTodas();
    });
  }

  /// Actualiza una categoría existente
  Future<void> actualizarCategoria(Categoria categoria) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repositorio.actualizar(categoria);
      return await _repositorio.obtenerTodas();
    });
  }

  /// Elimina una categoría por su ID
  Future<void> eliminarCategoria(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repositorio.eliminar(id);
      return await _repositorio.obtenerTodas();
    });
  }
}
