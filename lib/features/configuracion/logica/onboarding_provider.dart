import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_provider.g.dart';

/// Provider que controla si el onboarding ya fue completado
/// y almacena los datos de configuración inicial del usuario.
@Riverpod(keepAlive: true)
class OnboardingControlador extends _$OnboardingControlador {
  late SharedPreferences _prefs;

  @override
  FutureOr<bool> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getBool('onboardingCompleto') ?? false;
  }

  /// Guarda los datos del onboarding y lo marca como completado.
  Future<void> completarOnboarding({
    required String nombre,
    required double salarioMensual,
    double valorHoraExtra = 0,
  }) async {
    await _prefs.setString('nombreUsuario', nombre);
    await _prefs.setDouble('salarioMensual', salarioMensual);
    await _prefs.setDouble('valorHoraExtra', valorHoraExtra);
    await _prefs.setBool('onboardingCompleto', true);
    state = const AsyncData(true);
  }

  /// Obtiene el nombre del usuario guardado.
  String obtenerNombre() {
    return _prefs.getString('nombreUsuario') ?? '';
  }

  /// Obtiene el salario mensual guardado.
  double obtenerSalario() {
    return _prefs.getDouble('salarioMensual') ?? 0;
  }
}
