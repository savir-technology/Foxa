package com.alepoo.eats

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver.PendingResult
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import java.io.OutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.nio.charset.StandardCharsets
import java.net.URLEncoder

class IncomingCallActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent == null) {
            return
        }

        val pendingResult = goAsync()
        IncomingCallFirebaseService.stopRinging()

        val action = intent.action.orEmpty()
        val notificationId = parseInt(
            intent.getStringExtra(IncomingCallFirebaseService.EXTRA_NOTIFICATION_ID),
        )
        val orderId = parseInt(intent.getStringExtra("order_id"))
        val calleeId = parseInt(intent.getStringExtra("callee_id"))
        val extrasMap = intent.extras?.keySet()?.associateWith { key ->
            intent.extras?.get(key)?.toString().orEmpty()
        } ?: emptyMap()

        Log.i(
            TAG,
            "Receiver executed action=$action notificationId=$notificationId orderId=$orderId calleeId=$calleeId keys=${extrasMap.keys.joinToString(",")}",
        )

        val deliveryCheck = context.checkIncomingVoiceCallTarget(extrasMap)
        Log.i(
            TAG,
            "Receiver delivery check allowed=${deliveryCheck.allowed} reason=${deliveryCheck.reason} localUserId=${deliveryCheck.localUserId} calleeId=$calleeId callerId=${deliveryCheck.callerId}",
        )
        if (!deliveryCheck.allowed) {
            Log.w(
                TAG,
                "Rejecting action delivery for non-callee device reason=${deliveryCheck.reason} localUserId=${deliveryCheck.localUserId} callerId=${deliveryCheck.callerId} calleeId=$calleeId",
            )
            pendingResult.finish()
            return
        }

        try {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            if (notificationId > 0) {
                notificationManager?.cancel(notificationId)
            }

            if (action == IncomingCallFirebaseService.ACTION_ACCEPT) {
                Log.i(
                    TAG,
                    "Accept pressed notificationId=$notificationId orderId=$orderId calleeId=$calleeId",
                )
                launchCallScreen(context, intent)
                postMarkReadAsync(orderId, calleeId, notificationId, pendingResult)
                return
            }

            if (action == IncomingCallFirebaseService.ACTION_REJECT) {
                Log.i(
                    TAG,
                    "Reject pressed notificationId=$notificationId orderId=$orderId calleeId=$calleeId",
                )
                postDeclineAsync(
                    orderId = orderId,
                    calleeId = calleeId,
                    notificationId = notificationId,
                    intent = intent,
                    pendingResult = pendingResult,
                )
                return
            }
        } catch (error: Throwable) {
            Log.e(TAG, "Call action handling failed", error)
        }

        pendingResult.finish()
    }

    private fun launchCallScreen(context: Context, intent: Intent) {
        val launch = Intent(context, MainActivity::class.java).apply {
            flags =
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra("type", "voice_call")
            putExtra(
                IncomingCallFirebaseService.EXTRA_INCOMING_CALL_ACTION,
                "accept",
            )
            for (key in intent.extras?.keySet().orEmpty()) {
                val value = intent.extras?.get(key)
                if (value != null) {
                    putExtra(key, value.toString())
                }
            }
        }

        try {
            Log.i(
                TAG,
                "PendingIntent execution -> launching Flutter orderId=${intent.getStringExtra("order_id").orEmpty()} notificationId=${notificationIdFromIntent(intent)}",
            )
            val pi = PendingIntent.getActivity(
                context,
                9000 + notificationIdFromIntent(intent),
                launch,
                pendingIntentFlags(),
            )
            pi.send()
            Log.i(TAG, "PendingIntent execution -> launch sent")
            return
        } catch (sendErr: Throwable) {
            Log.e(TAG, "PendingIntent launch failed", sendErr)
        }

        try {
            Log.i(TAG, "Fallback startActivity for voice call launch")
            context.startActivity(launch)
            Log.i(TAG, "Fallback startActivity succeeded")
        } catch (startErr: Throwable) {
            Log.e(TAG, "startActivity failed", startErr)
        }
    }

    private fun postMarkReadAsync(
        orderId: Int,
        calleeId: Int,
        notificationId: Int,
        pendingResult: PendingResult,
    ) {
        Thread {
            try {
                if (calleeId <= 0 || notificationId <= 0) {
                    return@Thread
                }
                Log.i(
                    TAG,
                    "Accept pressed -> marking notification read calleeId=$calleeId notificationId=$notificationId orderId=$orderId",
                )
                postForm(
                    MARK_READ_URL,
                    "user_id=$calleeId&notification_id=$notificationId",
                )
                Log.i(
                    TAG,
                    "Accept pressed -> notification marked read calleeId=$calleeId notificationId=$notificationId",
                )
            } finally {
                pendingResult.finish()
            }
        }.start()
    }

    private fun postDeclineAsync(
        orderId: Int,
        calleeId: Int,
        notificationId: Int,
        intent: Intent,
        pendingResult: PendingResult,
    ) {
        Thread {
            try {
                if (orderId > 0) {
                    val body = buildString {
                        append("action=session_patch")
                        append("&order_id=").append(orderId)
                        append("&status=declined")
                    }
                    Log.i(
                        TAG,
                        "Reject pressed -> backend update request orderId=$orderId calleeId=$calleeId notificationId=$notificationId",
                    )
                    postForm(ORDER_CALLS_URL, body)
                    Log.i(
                        TAG,
                        "Reject pressed -> backend status updated orderId=$orderId status=declined",
                    )
                }

                if (orderId > 0) {
                    val callerRole = intent.getStringExtra("caller_role").orEmpty()
                    val callerId = intent.getStringExtra("caller_id").orEmpty()
                    val callerName = intent.getStringExtra("caller_name").orEmpty()
                    val calleeRole = intent.getStringExtra("callee_role").orEmpty()
                    val calleeName = intent.getStringExtra("callee_name").orEmpty()
                    val eventBody = buildString {
                        append("order_id=").append(orderId)
                        append("&event_type=").append(encodeFormComponent("declined"))
                        append("&status=").append(encodeFormComponent("declined"))
                        if (callerRole.isNotEmpty()) {
                            append("&caller_role=").append(encodeFormComponent(callerRole))
                        }
                        if (callerId.isNotEmpty()) {
                            append("&caller_ref_id=").append(encodeFormComponent(callerId))
                        }
                        if (callerName.isNotEmpty()) {
                            append("&caller_name=").append(encodeFormComponent(callerName))
                        }
                        if (calleeRole.isNotEmpty()) {
                            append("&callee_role=").append(encodeFormComponent(calleeRole))
                        }
                        if (calleeId > 0) {
                            append("&callee_ref_id=").append(encodeFormComponent(calleeId.toString()))
                        }
                        if (calleeName.isNotEmpty()) {
                            append("&callee_name=").append(encodeFormComponent(calleeName))
                        }
                    }
                    postForm(ORDER_CALLS_URL, eventBody)
                    Log.i(
                        TAG,
                        "Reject pressed -> event logged orderId=$orderId notificationId=$notificationId",
                    )
                }

                if (calleeId > 0 && notificationId > 0) {
                    postForm(
                        MARK_READ_URL,
                        "user_id=$calleeId&notification_id=$notificationId",
                    )
                    Log.i(
                        TAG,
                        "Reject pressed -> notification marked read calleeId=$calleeId notificationId=$notificationId",
                    )
                }
            } finally {
                pendingResult.finish()
            }
        }.start()
    }

    private fun notificationIdFromIntent(intent: Intent): Int {
        return parseInt(intent.getStringExtra(IncomingCallFirebaseService.EXTRA_NOTIFICATION_ID))
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

    private fun postForm(endpoint: String, body: String) {
        var connection: HttpURLConnection? = null
        try {
            val url = URL(endpoint)
            connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.connectTimeout = 8000
            connection.readTimeout = 8000
            connection.doOutput = true
            connection.setRequestProperty(
                "Content-Type",
                "application/x-www-form-urlencoded",
            )

            val bytes = body.toByteArray(StandardCharsets.UTF_8)
            connection.setFixedLengthStreamingMode(bytes.size)
            connection.outputStream.use { outputStream: OutputStream ->
                outputStream.write(bytes)
                outputStream.flush()
            }
            connection.responseCode
        } catch (error: Throwable) {
            Log.e(TAG, "POST failed: $endpoint", error)
        } finally {
            connection?.disconnect()
        }
    }

    private fun encodeFormComponent(value: String): String {
        return URLEncoder.encode(value, StandardCharsets.UTF_8.name())
    }

    companion object {
        private const val TAG = "IncomingCallActionRcvr"
        private const val ORDER_CALLS_URL =
            "https://savir-technology.online/roaqv2/calls/order_voice_call_events.php"
        private const val MARK_READ_URL =
            "https://savir-technology.online/roaqv2/notifications/mark_read.php"
    }
}
