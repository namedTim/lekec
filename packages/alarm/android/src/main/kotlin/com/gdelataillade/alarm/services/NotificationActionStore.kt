package com.gdelataillade.alarm.services

import android.content.Context
import io.flutter.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * Fork addition: a tiny durable queue of notification action button taps.
 *
 * Taps are recorded by [com.gdelataillade.alarm.alarm.AlarmReceiver] — which
 * can run while the Flutter engine is dead — and later drained by the app
 * through the `com.gdelataillade.alarm/notification_action` MethodChannel.
 *
 * Backed by a private [android.content.SharedPreferences] file (not the
 * Flutter `shared_preferences` store) so reads/writes work cross-process
 * without depending on a running engine. Writes use `commit()` so a tap is
 * durable before the alarm-stop signal reaches Flutter.
 */
object NotificationActionStore {
    private const val TAG = "NotificationActionStore"
    private const val PREFS_NAME = "com.gdelataillade.alarm.notification_actions"
    private const val KEY_QUEUE = "queue"

    /** Appends a tap to the queue. */
    @Synchronized
    fun record(context: Context, alarmId: Int, actionId: String) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val queue = JSONArray(prefs.getString(KEY_QUEUE, "[]"))
            queue.put(
                JSONObject()
                    .put("alarmId", alarmId)
                    .put("actionId", actionId)
            )
            prefs.edit().putString(KEY_QUEUE, queue.toString()).commit()
            Log.d(TAG, "Recorded action '$actionId' for alarm $alarmId")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to record action: ${e.message}")
        }
    }

    /** Returns every queued tap and clears the queue. */
    @Synchronized
    fun drain(context: Context): List<Map<String, Any>> {
        val result = mutableListOf<Map<String, Any>>()
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val queue = JSONArray(prefs.getString(KEY_QUEUE, "[]"))
            for (i in 0 until queue.length()) {
                val obj = queue.getJSONObject(i)
                result.add(
                    mapOf(
                        "alarmId" to obj.getInt("alarmId"),
                        "actionId" to obj.getString("actionId"),
                    )
                )
            }
            prefs.edit().remove(KEY_QUEUE).commit()
            if (result.isNotEmpty()) {
                Log.d(TAG, "Drained ${result.size} pending action(s)")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to drain actions: ${e.message}")
        }
        return result
    }
}
