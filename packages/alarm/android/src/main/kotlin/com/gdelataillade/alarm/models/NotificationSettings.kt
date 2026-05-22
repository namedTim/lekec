package com.gdelataillade.alarm.models

import android.graphics.Color
import com.gdelataillade.alarm.generated.NotificationSettingsWire
import io.flutter.Log
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json

/**
 * Fork addition: a custom action button rendered on the alarm notification.
 *
 * Tapping a button stops the alarm and records [id] so the Flutter app can act
 * on it (e.g. mark a medication as taken). See `NotificationActionStore`.
 */
@Serializable
data class NotificationActionButton(
    val id: String,
    val text: String,
)

@Serializable
data class NotificationSettings(
    val title: String,
    val body: String,
    val stopButton: String? = null,
    val icon: String? = null,
    val iconColor: Int? = null,
    // Fork addition. When non-empty these replace [stopButton] in the
    // notification. Defaulted so it survives the JSON round-trip through the
    // alarm Intent unchanged.
    val actionButtons: List<NotificationActionButton> = emptyList(),
) {
    companion object {
        private const val TAG = "NotificationSettings"

        // Lenient parser for the action-buttons wire payload.
        private val json = Json { ignoreUnknownKeys = true }

        fun fromWire(e: NotificationSettingsWire): NotificationSettings {
            val a = e.iconColorAlpha?.toFloat()
            val r = e.iconColorRed?.toFloat()
            val g = e.iconColorGreen?.toFloat()
            val b = e.iconColorBlue?.toFloat()

            var iconColor: Int? = null
            if (a != null && r != null && g != null && b != null) {
                iconColor = Color.argb(a, r, g, b)
            }

            // `actionButtons` arrives as a JSON-encoded string so the Pigeon
            // wire type only needs one extra trailing field.
            val actionButtons: List<NotificationActionButton> =
                e.actionButtons?.takeIf { it.isNotBlank() }?.let { raw ->
                    try {
                        json.decodeFromString(
                            ListSerializer(NotificationActionButton.serializer()),
                            raw,
                        )
                    } catch (ex: Exception) {
                        Log.e(TAG, "Failed to parse actionButtons: ${ex.message}")
                        emptyList()
                    }
                } ?: emptyList()

            return NotificationSettings(
                e.title,
                e.body,
                e.stopButton,
                e.icon,
                iconColor,
                actionButtons,
            )
        }
    }
}
