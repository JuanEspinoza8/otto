import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/base_de_datos/gestor_base_datos.dart';
import 'core/preferencias.dart';
import 'core/seguridad/proteccion_app.dart';
import 'core/tema/tema_app.dart';
import 'core/ui/enrutador_principal.dart';
import 'core/ui/pantalla_error_base.dart';
import 'features/configuracion/logica/onboarding_provider.dart';
import 'features/configuracion/logica/servicio_notificaciones.dart';
import 'features/configuracion/logica/tema_provider.dart';
import 'features/configuracion/vista/pantalla_onboarding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_AR', null);

  // La base se abre (y si hace falta se migra) antes de mostrar la app: si la
  // migración no cierra, se revierte y se avisa en vez de seguir con datos rotos.
  try {
    await GestorBaseDatos.instancia.obtenerBaseDatos();
  } catch (error) {
    runApp(AppErrorBase(error: error));
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  await ServicioNotificaciones.inicializar();
  try {
    // Reprogramar los recordatorios diarios si están activos y hay permiso.
    if ((prefs.getBool('recordatorioDiario') ?? false) && await ServicioNotificaciones.permisoConcedido()) {
      await ServicioNotificaciones.reprogramarNotificaciones(prefs.getStringList('horariosRecordatorios') ?? ['20:00']);
    }
  } catch (_) {/* las notificaciones no frenan el arranque */}

  runApp(
    ProviderScope(
      overrides: [preferenciasProvider.overrideWithValue(prefs)],
      child: const AppOtto(),
    ),
  );
}

class AppOtto extends ConsumerWidget {
  const AppOtto({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Otto',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.obtenerTemaClaro(),
      darkTheme: TemaApp.obtenerTemaOscuro(),
      themeMode: ref.watch(temaControladorProvider),
      // Por encima del Navigator: el bloqueo tapa también rutas y diálogos.
      builder: (context, child) => BarraDeEstadoDelTema(child: ProteccionApp(child: child!)),
      home: ref.watch(onboardingControladorProvider)
          ? const EnrutadorPrincipal()
          : const PantallaOnboarding(),
    );
  }
}
