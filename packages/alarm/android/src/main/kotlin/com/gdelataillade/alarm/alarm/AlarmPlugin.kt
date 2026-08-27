package com.gdelataillade.alarm.alarm

import com.gdelataillade.alarm.generated.AlarmApi
import com.gdelataillade.alarm.generated.AlarmTriggerApi
import android.app.Activity
import android.os.Build
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import com.gdelataillade.alarm.api.AlarmApiImpl
import com.gdelataillade.alarm.services.AlarmRingingLiveData
import com.gdelataillade.alarm.services.NotificationActionStore
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel

class AlarmPlugin : FlutterPlugin, ActivityAware {
    private var activity: Activity? = null

    // Fork addition: plain channel used by the app to drain notification
    // action button taps. Kept separate from the Pigeon API so it can be
    // added without regenerating the platform bindings.
    private var notificationActionChannel: MethodChannel? = null

    companion object {
        private const val TAG = "AlarmPlugin"

        const val NOTIFICATION_ACTION_CHANNEL =
            "com.gdelataillade.alarm/notification_action"

        @JvmStatic
        var alarmTriggerApi: AlarmTriggerApi? = null
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        AlarmApi.setUp(binding.binaryMessenger, AlarmApiImpl(binding.applicationContext))
        alarmTriggerApi = AlarmTriggerApi(binding.binaryMessenger)

        val appContext = binding.applicationContext
        notificationActionChannel = MethodChannel(
            binding.binaryMessenger,
            NOTIFICATION_ACTION_CHANNEL
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumePendingActions" ->
                        result.success(NotificationActionStore.drain(appContext))
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        alarmTriggerApi = null
        notificationActionChannel?.setMethodCallHandler(null)
        notificationActionChannel = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        AlarmRingingLiveData.instance.observe(
            binding.activity as LifecycleOwner,
            notificationObserver
        )
    }

    override fun onDetachedFromActivity() {
        activity = null
        AlarmRingingLiveData.instance.removeObserver(notificationObserver)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    private val notificationObserver = Observer<Boolean> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O_MR1) {
            Log.w(TAG, "Making app visible on lock screen is not supported on this version of Android.")
            return@Observer
        }
        val activity = activity ?: return@Observer
        if (it) {
            Log.d(TAG, "Making app visible on lock screen...")
            activity.setShowWhenLocked(true)
            activity.setTurnScreenOn(true)
            // Fork divergence: upstream also calls
            // KeyguardManager.requestDismissKeyguard here, which forces a
            // PIN/pattern prompt before the ring screen on secured devices.
            // setShowWhenLocked is enough to draw the ring UI over the
            // keyguard and let users tap the action buttons; if they want to
            // reach the rest of the app they unlock themselves.
        } else {
            Log.d(TAG, "Reverting making app visible on lock screen...")
            activity.setShowWhenLocked(false)
            activity.setTurnScreenOn(false)
        }
    }
}
