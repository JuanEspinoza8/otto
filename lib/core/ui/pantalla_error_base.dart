import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../base_de_datos/gestor_base_datos.dart';
import '../tema/tema_app.dart';

/// Se muestra si la base no se pudo abrir o migrar. La migración es una sola
/// transacción: si falla, los datos quedan como estaban y además hay una
/// copia del archivo previa a la migración.
class AppErrorBase extends StatelessWidget {
  const AppErrorBase({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Otto',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.obtenerTemaOscuro(),
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.shield_outlined, size: 64, color: TemaApp.verde),
                  const SizedBox(height: 16),
                  const Text(
                    'No pudimos actualizar tus datos',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No se perdió nada: tus datos quedaron como estaban y hay una copia guardada en el teléfono. '
                    'Mandale la copia a quien te instaló la app para que lo revise.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _compartirCopia(context),
                    icon: const Icon(Icons.share),
                    label: const Text('Compartir la copia'),
                  ),
                  const SizedBox(height: 16),
                  Text('$error', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _compartirCopia(BuildContext context) async {
    final mensajero = ScaffoldMessenger.of(context);
    final ruta = await GestorBaseDatos.instancia.rutaArchivo();
    final copia = File(p.join(p.dirname(ruta), GestorBaseDatos.nombreRespaldoV8));
    final archivo = await copia.exists() ? copia : File(ruta);
    if (!await archivo.exists()) {
      mensajero.showSnackBar(const SnackBar(content: Text('No se encontró la copia')));
      return;
    }
    await Share.shareXFiles([XFile(archivo.path)], text: 'Copia de la base de Otto');
  }
}
