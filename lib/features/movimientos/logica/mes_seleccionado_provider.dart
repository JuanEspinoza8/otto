import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mes_seleccionado_provider.g.dart';

@riverpod
class MesSeleccionado extends _$MesSeleccionado {
  @override
  DateTime build() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, 1);
  }

  void cambiarMes(DateTime nuevoMes) {
    state = DateTime(nuevoMes.year, nuevoMes.month, 1);
  }
}
