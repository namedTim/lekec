package com.gdelataillade.alarm.alarm

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import com.gdelataillade.alarm.services.NotificationActionStore

import io.flutter.Log

class AlarmReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_ALARM_STOP = "com.gdelataillade.alarm.ACTION_STOP"
        // Fork addition: a custom notification action button was tapped.
        const val ACTION_ALARM_ACTION = "com.gdelataillade.alarm.ACTION_ALARM_ACTION"
        const val EXTRA_ALARM_ACTION = "EXTRA_ALARM_ACTION"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(
            "AlarmReceiver",
            "onReceive action=$action id=${intent.getIntExtra("id", -1)}"
        )

        /// Stop alarm from notification stop button.
        if (action == ACTION_ALARM_STOP) {
            val id = intent.getIntExtra("id", 0)
            Log.d("AlarmReceiver", "Received stop alarm command from notification, id: $id")
            AlarmService.instance?.let {
                it.handleStopAlarmCommand(id)
                return
            }
        }

        /// Fork: a custom action button was tapped. Record the choice durably
        /// (so it survives the app being killed) then stop the alarm. The app
        /// drains the recorded actions via the notification_action channel.
        if (action == ACTION_ALARM_ACTION) {
            val id = intent.getIntExtra("id", 0)
            val actionId = intent.getStringExtra("actionId") ?: ""
            Log.d("AlarmReceiver", "Received notification action '$actionId' for alarm $id")
            NotificationActionStore.record(context, id, actionId)
            val service = AlarmService.instance
            if (service != null) {
                service.handleStopAlarmCommand(id)
            } else {
                // No running service — make sure the notification clears anyway.
                NotificationManagerCompat.from(context).cancel(id)
            }
            return
        }

        // Start Alarm Service
        val serviceIntent = Intent(context, AlarmService::class.java)
        serviceIntent.putExtras(intent)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val pendingIntent = PendingIntent.getForegroundService(
                context,
                1,
                serviceIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            pendingIntent.send()
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}