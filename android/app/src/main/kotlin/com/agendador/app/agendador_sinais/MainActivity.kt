package com.agendador.app.agendador_sinais

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Registrar o plugin de áudio em segundo plano
        flutterEngine.plugins.add(AudioBackgroundPlugin())
    }
}
