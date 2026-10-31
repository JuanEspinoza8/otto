import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/libro/libro_providers.dart';
import '../../recurrentes/logica/planes_provider.dart';
import '../../recurrentes/logica/servicio_planes.dart';
import '../repositorio/ajustes_repositorio.dart';
import 'servicio_notificaciones.dart';

part 'ajustes_provider.g.dart';

/// Preferencias del usuario. El sueldo es el plan de sueldo y el valor de la
/// hora extra vive en la base (viajan en el respaldo); el resto, en
/// SharedPreferences.
class Ajustes {
  const Ajustes({
    required this.biometriaActiva,
    required this.recordatorioDiario,
    required this.horariosRecordatorios,
    required this.nombreUsuario,
    required this.salarioMensual,
    required this.valorHoraExtra,
    required this.iaActiva,
  });

  final bool biometriaActiva;
  final bool recordatorioDiario;
  final List<String> horariosRecordatorios;
  final String nombreUsuario;
  final Dinero salarioMensual;
  final Dinero valorHoraExtra;

  /// Si Otto usa la IA (si no, el chat usa el parser local y el resumen no
  /// pide la devolución del contador).
  final bool iaActiva;
}

@Riverpod(keepAlive: true)
class AjustesControlador extends _$AjustesControlador {
  static const _kBiometria = 'biometriaActiva';
  static const _kRecordatorio = 'recordatorioDiario';
  static const _kHorarios = 'horariosRecordatorios';
  static const _kNombre = 'nombreUsuario';
  static const _kIa = 'iaActiva';

  @override
  Future<Ajustes> build() async {
    ref.watch(versionDatosProvider);
    final db = await ref.watch(baseDatosProvider.future);
    final prefs = await SharedPreferences.getInstance();
    final sueldo = await ServicioPlanes(db).sueldo();
    return Ajustes(
      biometriaActiva: prefs.getBool(_kBiometria) ?? false,
      recordatorioDiario: prefs.getBool(_kRecordatorio) ?? true,
      horariosRecordatorios: prefs.getStringList(_kHorarios) ?? const ['20:00'],
      nombreUsuario: prefs.getString(_kNombre) ?? '',
      salarioMensual: (sueldo != null && sueldo.activo) ? sueldo.monto : const Dinero.cero(),
      valorHoraExtra: await AjustesRepositorio(db).valorHoraExtra(),
      iaActiva: prefs.getBool(_kIa) ?? true,
    );
  }

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> alternarBiometria(bool valor) async {
    await (await _prefs).setBool(_kBiometria, valor);
    ref.invalidateSelf();
  }

  Future<void> alternarIa(bool valor) async {
    await (await _prefs).setBool(_kIa, valor);
    ref.invalidateSelf();
  }

  Future<void> alternarRecordatorioDiario(bool valor) async {
    await (await _prefs).setBool(_kRecordatorio, valor);
    ref.invalidateSelf();
    if (valor) {
      await ServicioNotificaciones.pedirPermisoNotificaciones();
      await ServicioNotificaciones.reprogramarNotificaciones((await future).horariosRecordatorios);
    } else {
      await ServicioNotificaciones.cancelarRecordatoriosDiarios();
    }
  }

  Future<void> agregarHorarioRecordatorio(String hora) async {
    final prefs = await _prefs;
    final horarios = [...prefs.getStringList(_kHorarios) ?? const ['20:00']];
    if (horarios.contains(hora)) return;
    horarios.add(hora);
    await _guardarHorarios(prefs, horarios);
  }

  /// Se pueden borrar todos los horarios: con la lista vacía no se programa nada.
  Future<void> eliminarHorarioRecordatorio(String hora) async {
    final prefs = await _prefs;
    final horarios = [...prefs.getStringList(_kHorarios) ?? const ['20:00']]..remove(hora);
    await _guardarHorarios(prefs, horarios);
  }

  Future<void> _guardarHorarios(SharedPreferences prefs, List<String> horarios) async {
    await prefs.setStringList(_kHorarios, horarios);
    ref.invalidateSelf();
    if (prefs.getBool(_kRecordatorio) ?? true) {
      await ServicioNotificaciones.reprogramarNotificaciones(horarios);
    }
  }

  Future<void> actualizarNombre(String nombre) async {
    await (await _prefs).setString(_kNombre, nombre.trim());
    ref.invalidateSelf();
  }

  /// Un sueldo de cero pausa el plan del sueldo (no borra su historial).
  Future<void> actualizarSalario(Dinero salario) =>
      escribirPlanes(ref, (p) => p.fijarSueldo(salario, hoy: DateTime.now()));

  Future<void> actualizarValorHoraExtra(Dinero valor) =>
      escribirEnTransaccion(ref, (txn) => AjustesRepositorio(txn).fijarValorHoraExtra(valor));
}
