package com.example.delvery

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val permissionChannelName = "driver_permissions"
    private val sharedPermissionChannelName = "notification_permissions"
    private val voiceCallIntentChannelName = "voice_call_intent"
    private val notificationPermissionCode = 2042
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var voiceCallIntentChannel: MethodChannel? = null
    private var initialVoiceCallData: Map<String, Any>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initialVoiceCallData = extractVoiceCallData(intent)
        prepareVoiceCallWindow(intent)
        Log.i(
            TAG,
            "MainActivity onCreate initialVoiceCallData=${initialVoiceCallData != null} keys=${initialVoiceCallData?.keys?.joinToString(",").orEmpty()}",
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        ensureNotificationChannels()
        super.configureFlutterEngine(flutterEngine)
        Log.i(TAG, "configureFlutterEngine() voice call bridge ready")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, permissionChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ensureNotificationPermission" -> ensureNotificationPermission(result)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, sharedPermissionChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ensureNotificationPermission" -> ensureNotificationPermission(result)
                    else -> result.notImplemented()
                }
            }

        voiceCallIntentChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            voiceCallIntentChannelName,
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialVoiceCallData" -> {
                        val data = consumeInitialVoiceCallData()
                        Log.i(
                            TAG,
                            "getInitialVoiceCallData() returned keys=${data?.keys?.joinToString(",").orEmpty()}",
                        )
                        result.success(data)
                    }
                    "stopRinging" -> {
                        try {
                            Log.i(TAG, "stopRinging() invoked from Flutter")
                            CallFirebaseMessagingService.stopRinging()
                        } catch (_: Throwable) {
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        initialVoiceCallData = extractVoiceCallData(intent) ?: initialVoiceCallData
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        this.intent = intent
        val data = extractVoiceCallData(intent)
        Log.i(
            TAG,
            "onNewIntent() voiceCallData=${data != null} action=${data?.get("incoming_call_action")?.toString().orEmpty()} orderId=${data?.get("order_id")?.toString().orEmpty()} notificationId=${data?.get("notification_id")?.toString().orEmpty()}",
        )
        if (data != null) {
            if (voiceCallIntentChannel == null) {
                initialVoiceCallData = data
            }
            prepareVoiceCallWindow(intent)
            voiceCallIntentChannel?.invokeMethod("onVoiceCallIntent", data)
            Log.i(TAG, "onNewIntent() forwarded voice call payload to Flutter")
        }
    }

    private fun prepareVoiceCallWindow(intent: Intent?) {
        if (extractVoiceCallData(intent) == null) {
            return
        }

        try {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            )
        } catch (_: Throwable) {
        }
    }

    private fun extractVoiceCallData(intent: Intent?): Map<String, Any>? {
        if (intent == null) {
            return null
        }

        val type = intent.getStringExtra("type")?.trim()?.lowercase() ?: ""
        if (type != "voice_call") {
            return null
        }

        val extras = intent.extras ?: return null
        val result = mutableMapOf<String, Any>()
        for (key in extras.keySet()) {
            val value = extras.get(key)
            if (value != null) {
                result[key] = value.toString()
            }
        }

        return result
    }

    private fun consumeInitialVoiceCallData(): Map<String, Any>? {
        val data = initialVoiceCallData
        initialVoiceCallData = null
        return data
    }

    private fun ensureNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        createChannel(
            notificationManager,
            channelId = "high_importance_channel",
            channelName = "General notifications",
            description = "Order, support, and system notifications",
            soundUri = Settings.System.DEFAULT_NOTIFICATION_URI,
            audioAttributes = audioAttributes,
        )

        createChannel(
            notificationManager,
            channelId = "voice_call_channel",
            channelName = "Incoming voice calls",
            description = "Ringtone used for incoming customer and driver calls",
            soundUri = Settings.System.DEFAULT_RINGTONE_URI,
            audioAttributes = audioAttributes,
        )
    }

    private fun createChannel(
        notificationManager: NotificationManager,
        channelId: String,
        channelName: String,
        description: String,
        soundUri: Uri,
        audioAttributes: AudioAttributes,
    ) {
        notificationManager.deleteNotificationChannel(channelId)
        val channel = NotificationChannel(
            channelId,
            channelName,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            this.description = description
            setSound(soundUri, audioAttributes)
            enableVibration(true)
            enableLights(true)
        }

        notificationManager.createNotificationChannel(channel)
    }

    private fun ensureNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }

        val granted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED

        if (granted) {
            result.success(true)
            return
        }

        pendingPermissionResult?.success(false)
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            notificationPermissionCode,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != notificationPermissionCode) {
            return
        }

        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED

        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
    }

    companion object {
        private const val TAG = "DriverVoiceCallMainActivity"
    }
}
