package com.gdelataillade.alarm.services

import android.annotation.SuppressLint
import com.gdelataillade.alarm.models.NotificationSettings
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import com.gdelataillade.alarm.alarm.AlarmReceiver

class NotificationHandler(private val context: Context) {
    companion object {
        private const val CHANNEL_ID = "alarm_plugin_channel"
        private const val CHANNEL_NAME = "Alarm Notification"
    }

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                setSound(null, null)
            }

            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    /// Fork: minimal silent notification whose only purpose is satisfying the
    /// startForegroundService() contract on service starts that stop again
    /// before a real alarm notification exists (stop actions, sticky restarts
    /// with a null intent, unparseable extras). Without it Android kills the
    /// app with ForegroundServiceDidNotStartInTimeException.
    fun buildPlaceholderNotification(): Notification {
        val appInfo = context.packageManager.getApplicationInfo(context.packageName, 0)
        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(appInfo.icon)
            .setContentTitle(context.packageManager.getApplicationLabel(appInfo).toString())
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setSilent(true)
            .setOngoing(true)
            .build()
    }

    // We need to use [Resources.getIdentifier] because resources are registered by Flutter.
    @SuppressLint("DiscouragedApi")
    fun buildNotification(
        notificationSettings: NotificationSettings,
        fullScreen: Boolean,
        pendingIntent: PendingIntent,
        alarmId: Int
    ): Notification {
        val defaultIconResId =
            context.packageManager.getApplicationInfo(context.packageName, 0).icon

        val iconResId = if (notificationSettings.icon != null) {
            val resId = context.resources.getIdentifier(
                notificationSettings.icon,
                "drawable",
                context.packageName
            )
            if (resId != 0) resId else defaultIconResId
        } else {
            defaultIconResId
        }

        val stopIntent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.ACTION_ALARM_STOP
            putExtra("id", alarmId)
        }
        val stopPendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notificationBuilder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(iconResId)
            .setContentTitle(notificationSettings.title)
            .setContentText(notificationSettings.body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setDeleteIntent(stopPendingIntent)
            .setSound(null)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        if (fullScreen) {
            notificationBuilder.setFullScreenIntent(pendingIntent, true)
        }

        notificationSettings.let {
            // Fork behaviour: custom action buttons take precedence over the
            // single stop button. Each button stops the alarm and reports its
            // id back to the app (see AlarmReceiver.ACTION_ALARM_ACTION).
            if (it.actionButtons.isNotEmpty()) {
                for (button in it.actionButtons) {
                    val actionIntent = Intent(context, AlarmReceiver::class.java).apply {
                        action = AlarmReceiver.ACTION_ALARM_ACTION
                        // A unique data Uri keeps each PendingIntent distinct
                        // (extras alone are ignored by Intent.filterEquals).
                        data = Uri.parse("alarm://$alarmId/action/${button.id}")
                        putExtra("id", alarmId)
                        putExtra("actionId", button.id)
                    }
                    val actionPendingIntent = PendingIntent.getBroadcast(
                        context,
                        0,
                        actionIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    notificationBuilder.addAction(0, button.text, actionPendingIntent)
                }
            } else if (it.stopButton != null) {
                notificationBuilder.addAction(0, it.stopButton, stopPendingIntent)
            }

            if (it.iconColor != null) {
                notificationBuilder.setColor(it.iconColor)
            }
        }

        return notificationBuilder.build()
    }
}
