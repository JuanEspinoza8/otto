import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../recurrentes/modelo/plan.dart';

/// Recordatorios diarios y avisos de gastos fijos.
///
/// Usa alarmas inexactas: para un recordatorio alcanzan y no requieren los
/// permisos restringidos de alarmas exactas ni excepciones de batería.
class ServicioNotificaciones {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Ids 0..99 para recordatorios diarios; desde 100, avisos de gastos fijos.
  static const int _baseIdFijos = 100;
  static const int _maxFijos = 60;

  static Future<void> inicializar() async {
    tz.initializeTimeZones();
    try {
      // Zona horaria del teléfono; sin esto tz.local queda en UTC y los avisos
      // salen corridos.
      final zona = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zona.identifier));
    } catch (_) {/* queda en UTC */}

    await _plugin.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Si la app puede mostrar notificaciones (en Android 13+ hace falta permiso).
  static Future<bool> permisoConcedido() async => await _android?.areNotificationsEnabled() ?? false;

  /// Pide el permiso de notificaciones. Devuelve si quedó concedido.
  static Future<bool> pedirPermiso() async {
    try {
      await _android?.requestNotificationsPermission();
    } catch (_) {/* versiones viejas no lo exponen */}
    return permisoConcedido();
  }

  static Future<void> reprogramarNotificaciones(List<String> horarios) async {
    await cancelarRecordatoriosDiarios();
    for (var i = 0; i < horarios.length && i < _baseIdFijos; i++) {
      final partes = horarios[i].split(':');
      if (partes.length != 2) continue;
      final hora = int.tryParse(partes[0]);
      final minuto = int.tryParse(partes[1]);
      if (hora == null || minuto == null) continue;
      await _plugin.zonedSchedule(
        i,
        '¿Ya cargaste tus gastos?',
        'Otto te recuerda anotar tus movimientos del día para no perder el control.',
        _proximaHora(hora, minuto),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'canal_recordatorios',
            'Recordatorios diarios',
            channelDescription: 'Recordatorio para cargar los gastos del día',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static tz.TZDateTime _proximaHora(int hora, int minuto) {
    final ahora = tz.TZDateTime.now(tz.local);
    var programada = tz.TZDateTime(tz.local, ahora.year, ahora.month, ahora.day, hora, minuto);
    if (programada.isBefore(ahora)) programada = programada.add(const Duration(days: 1));
    return programada;
  }

  /// Un aviso mensual dos días antes del débito de cada gasto fijo activo.
  static Future<void> reprogramarFijos(List<Plan> fijos) async {
    await _cancelarRango(_baseIdFijos, _baseIdFijos + _maxFijos);
    var id = _baseIdFijos;
    for (final f in fijos.where((f) => f.activo).take(_maxFijos)) {
      await _plugin.zonedSchedule(
        id++,
        'Se viene un gasto fijo 📅',
        'En unos días se debita "${f.nombre}". Cuando lo pagues, confirmalo en la app.',
        _proximoDia((f.diaDebito - 2).clamp(1, 28), 10, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'canal_fijos',
            'Avisos de gastos fijos',
            channelDescription: 'Aviso previo al débito de un gasto fijo',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    }
  }

  static tz.TZDateTime _proximoDia(int dia, int hora, int minuto) {
    final ahora = tz.TZDateTime.now(tz.local);
    var programada = tz.TZDateTime(tz.local, ahora.year, ahora.month, dia, hora, minuto);
    if (programada.isBefore(ahora)) {
      programada = tz.TZDateTime(tz.local, ahora.year, ahora.month + 1, dia, hora, minuto);
    }
    return programada;
  }

  /// Notificación inmediata para comprobar que llegan.
  static Future<void> mostrarPrueba() async {
    await pedirPermiso();
    await _plugin.show(
      999,
      '¡Hola! Soy Otto 🦫',
      'Las notificaciones están funcionando correctamente.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_prueba',
          'Prueba de notificaciones',
          channelDescription: 'Notificación de prueba',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> cancelarRecordatoriosDiarios() => _cancelarRango(0, _baseIdFijos);

  /// Cancela solo las notificaciones programadas de ese rango de ids.
  static Future<void> _cancelarRango(int desde, int hasta) async {
    final pendientes = await _plugin.pendingNotificationRequests();
    for (final p in pendientes) {
      if (p.id >= desde && p.id < hasta) await _plugin.cancel(p.id);
    }
  }
}
