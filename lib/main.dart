import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/base_de_datos/gestor_base_datos.dart';
import 'core/tema/tema_app.dart';
import 'core/ui/pantalla_error_base.dart';
import 'core/ui/enrutador_principal.dart';
import 'core/ui/widgets/filtro_privacidad.dart';
import 'core/ui/widgets/bloqueo_biometrico.dart';
import 'features/configuracion/logica/servicio_notificaciones.dart';
import 'features/configuracion/logica/onboarding_provider.dart';
import 'features/configuracion/logica/tema_provider.dart';
import 'features/configuracion/vista/pantalla_onboarding.dart';

void main() async {
  // Aseguramos que los bindings de Flutter estén inicializados antes de ejecutar asincronismo
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializamos el formateo de fechas para la región de Argentina (o genérico en español)
  await initializeDateFormatting('es_AR', null);

  // La base se abre (y si hace falta se migra) antes de mostrar la app: si la
  // migración no cierra, se revierte y se avisa en vez de seguir con datos rotos.
  try {
    await GestorBaseDatos.instancia.obtenerBaseDatos();
  } catch (error) {
    runApp(AppErrorBase(error: error));
    return;
  }

  // Inicializar notificaciones locales
  await ServicioNotificaciones.inicializar();

  // Reprogramar recordatorios diarios si el usuario los tiene activos.
  try {
    final prefs = await SharedPreferences.getInstance();
    final activos = prefs.getBool('recordatorioDiario') ?? true;
    if (activos) {
      final horarios = prefs.getStringList('horariosRecordatorios') ?? ['20:00'];
      await ServicioNotificaciones.reprogramarNotificaciones(horarios);
    }
  } catch (_) {/* no bloquear el arranque por notificaciones */}

  runApp(
    const ProviderScope(
      child: AplicacionFinanzas(),
    ),
  );
}

class AplicacionFinanzas extends ConsumerWidget {
  const AplicacionFinanzas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modoTema = ref.watch(temaControladorProvider);

    return MaterialApp(
      title: 'Otto',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.obtenerTemaClaro(),
      darkTheme: TemaApp.obtenerTemaOscuro(),
      themeMode: modoTema,
      home: const _SelectorInicial(),
    );
  }
}

/// Widget que decide si mostrar el onboarding o la app principal
/// basándose en si el usuario ya completó la configuración inicial.
class _SelectorInicial extends ConsumerWidget {
  const _SelectorInicial();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingControladorProvider);

    return onboardingAsync.when(
      loading: () => Scaffold(
        backgroundColor: context.colores.fondo,
        body: const Center(child: CircularProgressIndicator(color: TemaApp.verde)),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (completado) {
        if (completado) {
          return const FiltroPrivacidad(
            child: BloqueoBiometrico(
              child: EnrutadorPrincipal(),
            ),
          );
        }

        return PantallaOnboarding(
          alFinalizar: () {
            // Forzar rebuild — el provider ya se actualizó internamente
            ref.invalidate(onboardingControladorProvider);
          },
        );
      },
    );
  }
}
