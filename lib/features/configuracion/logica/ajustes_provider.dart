import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'servicio_notificaciones.dart';

part 'ajustes_provider.g.dart';

@Riverpod(keepAlive: true)
class AjustesControlador extends _$AjustesControlador {
  late SharedPreferences _prefs;

  @override
  FutureOr<Map<String, dynamic>> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _leerAjustes();
  }

  Map<String, dynamic> _leerAjustes() {
    return {
      'biometriaActiva': _prefs.getBool('biometriaActiva') ?? false,
      'recordatorioDiario': _prefs.getBool('recordatorioDiario') ?? true, // Activo por defecto
      'horariosRecordatorios': _prefs.getStringList('horariosRecordatorios') ?? ['20:00'], // Fijo por defecto a las 20:00
      'nombreUsuario': _prefs.getString('nombreUsuario') ?? '',
      'salarioMensual': _prefs.getDouble('salarioMensual') ?? 0.0,
      'valorHoraExtra': _prefs.getDouble('valorHoraExtra') ?? 0.0,
    };
  }

  Future<void> alternarBiometria(bool valor) async {
    await _prefs.setBool('biometriaActiva', valor);
    state = AsyncData(_leerAjustes());
  }

  Future<void> alternarRecordatorioDiario(bool valor) async {
    await _prefs.setBool('recordatorioDiario', valor);
    state = AsyncData(_leerAjustes());

    if (valor) {
      await ServicioNotificaciones.pedirPermisoNotificaciones();
      await ServicioNotificaciones.reprogramarNotificaciones(_leerAjustes()['horariosRecordatorios']);
      // Pedir eximir de la optimización de batería para que no se maten.
      await ServicioNotificaciones.pedirIgnorarOptimizacionBateria();
    } else {
      await ServicioNotificaciones.cancelarRecordatoriosDiarios();
    }
  }

  Future<void> agregarHorarioRecordatorio(String hora) async {
    final horarios = _prefs.getStringList('horariosRecordatorios') ?? ['20:00'];
    if (!horarios.contains(hora)) {
      horarios.add(hora);
      await _prefs.setStringList('horariosRecordatorios', horarios);
      state = AsyncData(_leerAjustes());
      
      if (_leerAjustes()['recordatorioDiario'] == true) {
        await ServicioNotificaciones.reprogramarNotificaciones(horarios);
      }
    }
  }

  Future<void> eliminarHorarioRecordatorio(String hora) async {
    final horarios = _prefs.getStringList('horariosRecordatorios') ?? ['20:00'];
    horarios.remove(hora);
    // Se permite borrar todos los horarios (incluido el de las 20:00). Si la
    // lista queda vacía, simplemente no se programan recordatorios.
    await _prefs.setStringList('horariosRecordatorios', horarios);
    state = AsyncData(_leerAjustes());

    if (_leerAjustes()['recordatorioDiario'] == true) {
      await ServicioNotificaciones.reprogramarNotificaciones(horarios);
    }
  }

  /// Actualiza el nombre del usuario.
  Future<void> actualizarNombre(String nombre) async {
    await _prefs.setString('nombreUsuario', nombre);
    state = AsyncData(_leerAjustes());
  }

  /// Actualiza el salario mensual del usuario.
  Future<void> actualizarSalario(double salario) async {
    await _prefs.setDouble('salarioMensual', salario);
    state = AsyncData(_leerAjustes());
  }

  /// Actualiza el valor de la hora extra (en pesos).
  Future<void> actualizarValorHoraExtra(double valor) async {
    await _prefs.setDouble('valorHoraExtra', valor);
    state = AsyncData(_leerAjustes());
  }
}
