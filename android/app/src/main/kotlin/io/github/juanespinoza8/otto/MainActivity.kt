package io.github.juanespinoza8.otto

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Con el bloqueo activado, FLAG_SECURE oculta la app en la vista de
        // recientes y bloquea las capturas de pantalla.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "otto/seguridad").setMethodCallHandler { call, result ->
            if (call.method == "protegerPantalla") {
                if (call.arguments == true) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
