import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/dinero/dinero.dart';
import '../../../core/libro/libro_providers.dart';
import '../../../core/libro/servicio_libro.dart';
import '../../../core/seguridad/autenticador.dart';
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
    required this.bannerRecordatorioOculto,
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

  /// Si el usuario descartó el banner que ofrece activar los recordatorios.
  final bool bannerRecordatorioOculto;
}

@Riverpod(keepAlive: true)
class AjustesControlador extends _$AjustesControlador {
  static const _kBiometria = 'biometriaActiva';
  static const _kRecordatorio = 'recordatorioDiario';
  static const _kHorarios = 'horariosRecordatorios';
  static const _kNombre = 'nombreUsuario';
  static const _kIa = 'iaActiva';
  static const _kBannerOculto = 'recordatorioBannerOculto';

  @override
  Future<Ajustes> build() async {
    ref.watch(versionDatosProvider);
    final db = await ref.watch(baseDatosProvider.future);
    final prefs = await SharedPreferences.getInstance();
    final sueldo = await ServicioPlanes(db).sueldo();
    return Ajustes(
      biometriaActiva: prefs.getBool(_kBiometria) ?? false,
      // Activo solo si el usuario lo prendió y el teléfono da el permiso: si
      // no, el switch quedaría en ON sin que llegue nada.
      recordatorioDiario: (prefs.getBool(_kRecordatorio) ?? false) && await _permisoNotificaciones(),
      horariosRecordatorios: prefs.getStringList(_kHorarios) ?? const ['20:00'],
      nombreUsuario: prefs.getString(_kNombre) ?? '',
      salarioMensual: (sueldo != null && sueldo.activo) ? sueldo.monto : const Dinero.cero(),
      valorHoraExtra: await AjustesRepositorio(db).valorHoraExtra(),
      iaActiva: prefs.getBool(_kIa) ?? true,
      bannerRecordatorioOculto: prefs.getBool(_kBannerOculto) ?? false,
    );
  }

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<bool> _permisoNotificaciones() async {
    try {
      return await ServicioNotificaciones.permisoConcedido();
    } catch (_) {
      return false;
    }
  }

  Future<void> ocultarBannerRecordatorio() async {
    await (await _prefs).setBool(_kBannerOculto, true);
    ref.invalidateSelf();
  }

  /// Para activarlo, el teléfono tiene que tener un bloqueo configurado y el
  /// usuario tiene que autenticarse una vez (así no queda afuera de la app).
  Future<void> alternarBiometria(bool valor) async {
    if (valor) {
      final autenticador = ref.read(autenticadorProvider);
      if (!await autenticador.disponible()) {
        throw const ErrorLibro('Configurá un bloqueo de pantalla o una huella en el teléfono primero');
      }
      if (!await autenticador.autenticar('Confirmá para activar el bloqueo de Otto')) {
        throw const ErrorLibro('No se pudo verificar: el bloqueo sigue desactivado');
      }
    }
    await (await _prefs).setBool(_kBiometria, valor);
    ref.invalidateSelf();
  }

  Future<void> alternarIa(bool valor) async {
    await (await _prefs).setBool(_kIa, valor);
    ref.invalidateSelf();
  }

  Future<void> activarRecordatorioDiario() => alternarRecordatorioDiario(true);

  /// Para activarlo pide el permiso de notificaciones; si se niega, queda
  /// apagado y se avisa.
  Future<void> alternarRecordatorioDiario(bool valor) async {
    final prefs = await _prefs;
    if (valor && !await ServicioNotificaciones.pedirPermiso()) {
      throw const ErrorLibro('Activá las notificaciones de Otto en los ajustes del teléfono');
    }
    await prefs.setBool(_kRecordatorio, valor);
    ref.invalidateSelf();
    if (valor) {
      await ServicioNotificaciones.reprogramarNotificaciones(prefs.getStringList(_kHorarios) ?? const ['20:00']);
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
    if (prefs.getBool(_kRecordatorio) ?? false) {
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
