import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preferencias.g.dart';

/// SharedPreferences ya cargadas. Se inicializa en `main()` antes de
/// `runApp`, así el tema y el onboarding se leen sin esperar (sin parpadeo).
@Riverpod(keepAlive: true)
SharedPreferences preferencias(Ref ref) =>
    throw UnimplementedError('preferenciasProvider se sobreescribe en main()');
