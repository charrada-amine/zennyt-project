package com.example.zenny

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Commande le moteur de vibration directement, au lieu de passer par le retour
 * haptique tactile d'Android.
 *
 * Pourquoi ce canal existe : `HapticFeedback` de Flutter appelle
 * `View.performHapticFeedback`, qu'Android n'exécute que si le réglage système
 * « Vibration au toucher » (`Settings.System.HAPTIC_FEEDBACK_ENABLED`) est actif.
 * Quand il ne l'est pas — le défaut sur beaucoup de Xiaomi/Redmi — la demande est
 * ignorée SANS erreur : le code s'exécute, rien ne vibre, et rien ne le signale.
 * C'est exactement le symptôme remonté sur la vibration d'erreur d'Optimal Path.
 *
 * Le service `Vibrator`, lui, ne dépend que de la permission `VIBRATE`, déclarée
 * au manifeste. Il reste soumis au mode silencieux/Ne pas déranger de l'appareil,
 * ce qui est le comportement attendu.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "vibrate" -> result.success(
                        vibrate(
                            (call.argument<Int>("milliseconds") ?: DEFAULT_MS).toLong(),
                            call.argument<Int>("amplitude") ?: -1,
                        )
                    )
                    "hasVibrator" -> result.success(vibrator()?.hasVibrator() == true)
                    else -> result.notImplemented()
                }
            }
    }

    private fun vibrator(): Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)
                ?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }

    /**
     * Retourne `false` si l'appareil n'a pas de moteur ou si le système a refusé
     * l'effet. L'appelant Dart reprend alors le chemin `HapticFeedback`, plutôt
     * que de laisser le joueur sans aucun retour.
     */
    private fun vibrate(milliseconds: Long, amplitude: Int): Boolean {
        val vibrator = vibrator() ?: return false
        if (!vibrator.hasVibrator()) return false
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Tous les appareils ne savent pas moduler l'intensité : sans
                // contrôle d'amplitude, `DEFAULT_AMPLITUDE` évite un effet muet.
                val effective =
                    if (amplitude in 1..255 && vibrator.hasAmplitudeControl()) {
                        amplitude
                    } else {
                        VibrationEffect.DEFAULT_AMPLITUDE
                    }
                vibrator.vibrate(VibrationEffect.createOneShot(milliseconds, effective))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(milliseconds)
            }
            true
        } catch (error: Exception) {
            false
        }
    }

    private companion object {
        const val CHANNEL = "zennyt/haptics"
        const val DEFAULT_MS = 40
    }
}
