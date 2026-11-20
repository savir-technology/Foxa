package com.alepoo.eats

import android.app.ActivityManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.Person
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService
import android.util.Log
import java.util.Locale

class IncomingCallFirebaseService : FlutterFirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        val data = remoteMessage.data
        val type = data["type"]?.trim()?.lowercase() ?: ""
        Log.i(
            TAG,
            "Incoming FCM received type=$type keys=${data.keys.joinToString(",")}",
        )
        if (type == "voice_call_status") {
            Log.i(TAG, "Incoming voice_call_status received, stopping ringtone")
            stopRinging()
            super.onMessageReceived(remoteMessage)
            return
        }
        if (type != "voice_call") {
            super.onMessageReceived(remoteMessage)
            return
        }

        showIncomingCallNotification(data)
    }

    private fun showIncomingCallNotification(data: Map<String, String>) {
        val orderId = parseInt(data["order_id"])
        val callerId = parseInt(data["caller_id"])
        val calleeId = parseInt(data["callee_id"])
        val notificationId = notificationIdForOrder(orderId)
        val deliveryCheck = checkIncomingVoiceCallTarget(data)

        Log.i(
            TAG,
            "Incoming voice_call delivery check allowed=${deliveryCheck.allowed} reason=${deliveryCheck.reason} localUserId=${deliveryCheck.localUserId} calleeId=$calleeId callerId=$callerId notificationId=$notificationId",
        )
        Log.i(
            TAG,
            "Incoming voice_call target destinationRole=${deliveryCheck.calleeRole} destinationUserId=${deliveryCheck.localUserId} callerId=$callerId receiverId=$calleeId",
        )

        if (!deliveryCheck.allowed) {
            Log.w(
                TAG,
                "Ignoring voice_call for this device reason=${deliveryCheck.reason} localUserId=${deliveryCheck.localUserId} callerId=$callerId calleeId=$calleeId",
            )
            stopRinging()
            return
        }

        if (orderId <= 0 || callerId <= 0 || calleeId <= 0) {
            Log.w(
                TAG,
                "Ignoring voice_call with invalid identifiers orderId=$orderId callerId=$callerId calleeId=$calleeId",
            )
            return
        }

        val callerName = callerDisplayName(data)
        val body = buildCallBody(callerName, orderId)

        val now = System.currentTimeMillis()
        if (orderId == lastNotifiedOrderId && now - lastNotifiedAtMs < 4000L) {
            return
        }
        lastNotifiedOrderId = orderId
        lastNotifiedAtMs = now

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: return

        ensureCallsChannel(notificationManager)
        stopRinging()
        startRinging(notificationId, notificationManager)
        lastNotificationId = notificationId
        notificationContext = applicationContext

        val openIntent = buildMainActivityIntent(
            data = data,
            action = "open",
        )
        val acceptIntent = buildReceiverIntent(
            action = ACTION_ACCEPT,
            data = data,
        )
        val rejectIntent = buildReceiverIntent(
            action = ACTION_REJECT,
            data = data,
        )

        val flags = pendingIntentFlags()
        val contentPendingIntent = PendingIntent.getActivity(
            this,
            notificationId,
            openIntent,
            flags,
        )
        val acceptPendingIntent = PendingIntent.getBroadcast(
            this,
            notificationId + 1,
            acceptIntent,
            flags,
        )
        val rejectPendingIntent = PendingIntent.getBroadcast(
            this,
            notificationId + 2,
            rejectIntent,
            flags,
        )

        Log.i(
            TAG,
            "PendingIntent created notificationId=$notificationId contentRequestCode=$notificationId acceptRequestCode=${notificationId + 1} rejectRequestCode=${notificationId + 2} orderId=$orderId",
        )

        val callStyle = NotificationCompat.CallStyle.forIncomingCall(
            Person.Builder().setName(callerName).build(),
            rejectPendingIntent,
            acceptPendingIntent,
        )

        val notification = NotificationCompat.Builder(this, CALLS_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(callerName)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setDefaults(Notification.DEFAULT_VIBRATE)
            .setAutoCancel(false)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(contentPendingIntent)
            .setFullScreenIntent(contentPendingIntent, true)
            .setStyle(callStyle)
            .build()

        notificationManager.notify(notificationId, notification)
        Log.i(
            TAG,
            "Incoming call notification shown notificationId=$notificationId orderId=$orderId callerId=$callerId calleeId=$calleeId",
        )
    }

    private fun callerDisplayName(data: Map<String, String>): String {
        val callerName = data["caller_name"]?.trim().orEmpty()
        if (callerName.isNotEmpty()) {
            return callerName
        }

        val callerRole = data["caller_role"]?.trim()?.lowercase(Locale.ROOT).orEmpty()
        return when (callerRole) {
            "driver" -> if (isArabicLocale()) "السائق" else "Driver"
            "user", "customer" -> if (isArabicLocale()) "العميل" else "Customer"
            else -> if (isArabicLocale()) "مكالمة صوتية" else "Voice call"
        }
    }

    private fun buildCallBody(
        callerName: String,
        orderId: Int,
    ): String {
        val orderLabel = if (orderId > 0) "#$orderId" else ""
        return if (isArabicLocale()) {
            if (orderLabel.isNotEmpty()) {
                "$callerName يتصل بك بخصوص الطلب $orderLabel"
            } else {
                "$callerName يتصل بك الآن"
            }
        } else {
            if (orderLabel.isNotEmpty()) {
                "$callerName is calling about order $orderLabel"
            } else {
                "$callerName is calling now"
            }
        }
    }

    private fun isArabicLocale(): Boolean {
        return Locale.getDefault().language.equals("ar", ignoreCase = true)
    }

    private fun buildMainActivityIntent(
        data: Map<String, String>,
        action: String,
    ): Intent {
        Log.i(
            TAG,
            "Building MainActivity PendingIntent action=$action notificationId=${data["notification_id"].orEmpty()} orderId=${data["order_id"].orEmpty()}",
        )
        return Intent(this, MainActivity::class.java).apply {
            flags =
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("type", "voice_call")
            putExtra(EXTRA_INCOMING_CALL_ACTION, action)
            putExtra(EXTRA_NOTIFICATION_ID, data["notification_id"].orEmpty())
            for ((key, value) in data) {
                putExtra(key, value)
            }
        }
    }

    private fun buildReceiverIntent(
        action: String,
        data: Map<String, String>,
    ): Intent {
        Log.i(
            TAG,
            "Building broadcast PendingIntent action=$action notificationId=${data["notification_id"].orEmpty()} orderId=${data["order_id"].orEmpty()}",
        )
        return Intent(this, IncomingCallActionReceiver::class.java).apply {
            this.action = action
            putExtra("type", "voice_call")
            putExtra(EXTRA_INCOMING_CALL_ACTION, action)
            putExtra(EXTRA_NOTIFICATION_ID, data["notification_id"].orEmpty())
            for ((key, value) in data) {
                putExtra(key, value)
            }
        }
    }

    private fun ensureCallsChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        notificationManager.deleteNotificationChannel(CALLS_CHANNEL_ID)

        val channel = NotificationChannel(
            CALLS_CHANNEL_ID,
            "Incoming Calls",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Incoming call notifications"
            setSound(null, null)
            enableVibration(true)
            enableLights(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }

        notificationManager.createNotificationChannel(channel)
    }

    private fun startRinging(
        notificationId: Int,
        notificationManager: NotificationManager,
    ) {
        try {
            var ringtoneUri = RingtoneManager.getDefaultUri(
                RingtoneManager.TYPE_RINGTONE,
            )
            if (ringtoneUri == null) {
                ringtoneUri = RingtoneManager.getDefaultUri(
                    RingtoneManager.TYPE_NOTIFICATION,
                )
            }
            activeRingtone = RingtoneManager.getRingtone(
                applicationContext,
                ringtoneUri,
            )
            activeRingtone?.let { ringtone ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    ringtone.isLooping = true
                }
                ringtone.play()
            }
        } catch (_: Throwable) {
        }

        stopRingingTask?.let {
            MAIN_HANDLER.removeCallbacks(it)
        }
        stopRingingTask = Runnable {
            stopRinging()
            try {
                notificationManager.cancel(notificationId)
            } catch (_: Throwable) {
            }
        }
        MAIN_HANDLER.postDelayed(stopRingingTask!!, CALL_RING_TIMEOUT_MS)
    }

    private fun isAppInForeground(): Boolean {
        val activityManager =
            getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                ?: return false
        val processes = activityManager.runningAppProcesses ?: return false
        val processName = packageName

        for (processInfo in processes) {
            if (processInfo.processName != processName) {
                continue
            }

            val importance = processInfo.importance
            return importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND ||
                importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE
        }

        return false
    }

    private fun notificationIdForOrder(orderId: Int): Int {
        return if (orderId > 0) orderId else CALL_NOTIFICATION_ID
    }

    private fun parseInt(value: String?): Int {
        return try {
            value?.trim()?.toInt() ?: 0
        } catch (_: Throwable) {
            0
        }
    }

    private fun pendingIntentFlags(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
    }

    companion object {
        const val ACTION_ACCEPT = "com.alepoo.eats.ACTION_ACCEPT_CALL"
        const val ACTION_REJECT = "com.alepoo.eats.ACTION_REJECT_CALL"
        const val EXTRA_INCOMING_CALL_ACTION = "incoming_call_action"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val CALLS_CHANNEL_ID = "calls_ring_v3"
        const val CALL_NOTIFICATION_ID = 1138
        private const val TAG = "IncomingCallFirebaseSvc"

        private const val CALL_RING_TIMEOUT_MS = 35000L
        private val MAIN_HANDLER = Handler(Looper.getMainLooper())
        private var activeRingtone: Ringtone? = null
        private var stopRingingTask: Runnable? = null
        private var lastNotifiedOrderId: Int = 0
        private var lastNotifiedAtMs: Long = 0L
        private var lastNotificationId: Int = 0
        private var notificationContext: Context? = null

        @JvmStatic
        fun stopRinging() {
            stopRingingTask?.let {
                MAIN_HANDLER.removeCallbacks(it)
            }
            stopRingingTask = null

            try {
                val manager = notificationContext?.getSystemService(
                    Context.NOTIFICATION_SERVICE,
                ) as? NotificationManager
                if (lastNotificationId > 0) {
                    manager?.cancel(lastNotificationId)
                }
            } catch (_: Throwable) {
            }
            lastNotificationId = 0
            notificationContext = null

            try {
                if (activeRingtone?.isPlaying == true) {
                    activeRingtone?.stop()
                }
            } catch (_: Throwable) {
            } finally {
                activeRingtone = null
            }
        }
    }
}
