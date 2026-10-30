import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../recurrentes/modelo/gasto_fijo.dart';

class ServicioNotificaciones {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Rango de ids reservado para recordatorios de gastos fijos.
  static const int _baseIdFijos = 100;

  static Future<void> inicializar() async {
    tz.initializeTimeZones();
    // IMPORTANTE: sin esto tz.local queda en UTC y los recordatorios se
    // programan con ~3 h de diferencia (o nunca disparan a la hora esperada).
    try {
      tz.setLocalLocation(tz.getLocation('America/Argentina/Buenos_Aires'));
    } catch (_) {/* fallback: queda en UTC */}

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuración genérica (sin iOS porque se pidió Android/multiplataforma pero enfocamos Android por ahora)
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _plugin.initialize(initializationSettings);
    // El permiso de notificaciones NO se pide acá (al arrancar, antes del
    // onboarding): se pide recién cuando el usuario activa los recordatorios
    // (ver pedirPermisoNotificaciones).
  }

  /// Pide el permiso de notificaciones (Android 13+) y de alarmas exactas.
  /// Se llama cuando el usuario ACTIVA los recordatorios, no al arrancar.
  static Future<void> pedirPermisoNotificaciones() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    try {
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } catch (_) {/* algunas versiones no exponen estos métodos */}
  }

  static Future<void> reprogramarNotificaciones(List<String> horarios) async {
    // Cancelamos SÓLO el rango de recordatorios diarios (no los avisos de
    // gastos fijos, que viven en el rango _baseIdFijos+). Antes se usaba
    // cancelAll() y borraba los avisos de fijos en cada arranque de la app.
    await cancelarRecordatoriosDiarios();

    for (int i = 0; i < horarios.length; i++) {
      final horaParts = horarios[i].split(':');
      if (horaParts.length == 2) {
        final hora = int.parse(horaParts[0]);
        final minuto = int.parse(horaParts[1]);
        
        await _programarNotificacionDiaria(
          id: i,
          titulo: '¿Ya cargaste tus gastos?',
          cuerpo: 'Otto te recuerda anotar tus movimientos del día para no perder el control.',
          hora: hora,
          minuto: minuto,
        );
      }
    }
  }

  static Future<void> _programarNotificacionDiaria({
    required int id,
    required String titulo,
    required String cuerpo,
    required int hora,
    required int minuto,
  }) async {
    await _plugin.zonedSchedule(
      id,
      titulo,
      cuerpo,
      _siguienteInstanciaDe(hora, minuto),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_recordatorios',
          'Recordatorios Diarios',
          channelDescription: 'Canal para recordatorios de carga de gastos',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repetir todos los días a la misma hora
    );
  }

  static tz.TZDateTime _siguienteInstanciaDe(int hora, int minuto) {
    final tz.TZDateTime ahora = tz.TZDateTime.now(tz.local);
    tz.TZDateTime programada = tz.TZDateTime(tz.local, ahora.year, ahora.month, ahora.day, hora, minuto);
    if (programada.isBefore(ahora)) {
      programada = programada.add(const Duration(days: 1));
    }
    return programada;
  }

  /// Reprograma un aviso mensual, 2 días antes del débito de cada gasto fijo.
  static Future<void> reprogramarFijos(List<GastoFijo> fijos) async {
    // Limpiamos el rango reservado para fijos.
    for (int i = _baseIdFijos; i < _baseIdFijos + 60; i++) {
      await _plugin.cancel(i);
    }
    int idx = _baseIdFijos;
    for (final f in fijos) {
      if (!f.activo) continue;
      final diaAviso = (f.diaDebito - 2).clamp(1, 28);
      await _plugin.zonedSchedule(
        idx++,
        'Se viene un gasto fijo 📅',
        'En unos días se debita "${f.nombre}". Cuando lo pagues, confirmalo en la app.',
        _siguienteInstanciaMensual(diaAviso, 10, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'canal_fijos',
            'Avisos de gastos fijos',
            channelDescription: 'Recordatorio previo al débito de gastos fijos',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime, // repetir cada mes ese día
      );
      if (idx >= _baseIdFijos + 60) break;
    }
  }

  static tz.TZDateTime _siguienteInstanciaMensual(int dia, int hora, int minuto) {
    final ahora = tz.TZDateTime.now(tz.local);
    var programada = tz.TZDateTime(tz.local, ahora.year, ahora.month, dia, hora, minuto);
    if (programada.isBefore(ahora)) {
      programada = tz.TZDateTime(tz.local, ahora.year, ahora.month + 1, dia, hora, minuto);
    }
    return programada;
  }

  static const MethodChannel _canal = MethodChannel('otto/bateria');

  /// Pide al usuario (con un diálogo del sistema) eximir a la app de la
  /// optimización de batería, para que las notificaciones programadas no se
  /// maten en segundo plano (importante en Samsung/Xiaomi). Implementado con
  /// un MethodChannel nativo (sin dependencias extra).
  static Future<void> pedirIgnorarOptimizacionBateria() async {
    try {
      await _canal.invokeMethod('pedirIgnorarBateria');
    } catch (_) {/* no disponible en algunos dispositivos */}
  }

  /// Muestra una notificación inmediata (para que el usuario verifique que las
  /// notificaciones están habilitadas).
  static Future<void> mostrarPrueba() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    try {
      await android?.requestNotificationsPermission();
    } catch (_) {}
    await _plugin.show(
      999,
      '¡Hola! Soy Otto 🦫',
      'Las notificaciones están funcionando correctamente.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_prueba',
          'Prueba de notificaciones',
          channelDescription: 'Notificación de prueba',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Cancela sólo el rango de recordatorios diarios (ids 0.._baseIdFijos-1),
  /// preservando los avisos de gastos fijos (ids _baseIdFijos+).
  static Future<void> cancelarRecordatoriosDiarios() async {
    for (int i = 0; i < _baseIdFijos; i++) {
      await _plugin.cancel(i);
    }
  }

  static Future<void> cancelarTodas() async {
    await _plugin.cancelAll();
  }
}
