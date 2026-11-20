package com.alepoo.eats

import android.content.Context
import android.content.SharedPreferences

private const val FLUTTER_SHARED_PREFS_NAME = "FlutterSharedPreferences"
private const val FLUTTER_PREFIX = "flutter."

data class VoiceCallDeliveryCheck(
    val allowed: Boolean,
    val reason: String,
    val localUserId: Int,
    val localUsername: String,
    val callerId: Int,
    val callerRole: String,
    val calleeId: Int,
    val calleeRole: String,
)

fun Context.checkIncomingVoiceCallTarget(data: Map<String, String>): VoiceCallDeliveryCheck {
    val prefs = getSharedPreferences(FLUTTER_SHARED_PREFS_NAME, Context.MODE_PRIVATE)
    val localUserId = prefs.readFlutterInt("id")
    val localUsername = prefs.readFlutterString("username")
    val callerId = parseInt(data["caller_id"])
    val callerRole = data["caller_role"]?.trim()?.lowercase().orEmpty()
    val calleeId = parseInt(data["callee_id"])
    val calleeRole = normalizeRole(data["callee_role"])

    if (localUserId <= 0) {
        return VoiceCallDeliveryCheck(
            allowed = false,
            reason = "local_user_missing",
            localUserId = localUserId,
            localUsername = localUsername,
            callerId = callerId,
            callerRole = callerRole,
            calleeId = calleeId,
            calleeRole = calleeRole,
        )
    }

    if (calleeRole != "user") {
        return VoiceCallDeliveryCheck(
            allowed = false,
            reason = "callee_role_mismatch",
            localUserId = localUserId,
            localUsername = localUsername,
            callerId = callerId,
            callerRole = callerRole,
            calleeId = calleeId,
            calleeRole = calleeRole,
        )
    }

    if (calleeId <= 0) {
        return VoiceCallDeliveryCheck(
            allowed = false,
            reason = "callee_id_missing",
            localUserId = localUserId,
            localUsername = localUsername,
            callerId = callerId,
            callerRole = callerRole,
            calleeId = calleeId,
            calleeRole = calleeRole,
        )
    }

    if (calleeId != localUserId) {
        return VoiceCallDeliveryCheck(
            allowed = false,
            reason = "callee_id_mismatch",
            localUserId = localUserId,
            localUsername = localUsername,
            callerId = callerId,
            callerRole = callerRole,
            calleeId = calleeId,
            calleeRole = calleeRole,
        )
    }

    if (callerId > 0 && callerId == localUserId) {
        return VoiceCallDeliveryCheck(
            allowed = false,
            reason = "caller_matches_local_user",
            localUserId = localUserId,
            localUsername = localUsername,
            callerId = callerId,
            callerRole = callerRole,
            calleeId = calleeId,
            calleeRole = calleeRole,
        )
    }

    return VoiceCallDeliveryCheck(
        allowed = true,
        reason = "matched",
        localUserId = localUserId,
        localUsername = localUsername,
        callerId = callerId,
        callerRole = callerRole,
        calleeId = calleeId,
        calleeRole = calleeRole,
    )
}

private fun SharedPreferences.readFlutterInt(key: String): Int {
    val storedKey = "$FLUTTER_PREFIX$key"
    if (!contains(storedKey)) {
        return 0
    }

    return try {
        getLong(storedKey, 0L).toInt()
    } catch (_: Throwable) {
        try {
            getInt(storedKey, 0)
        } catch (_: Throwable) {
            0
        }
    }
}

private fun SharedPreferences.readFlutterString(key: String): String {
    val storedKey = "$FLUTTER_PREFIX$key"
    return try {
        getString(storedKey, "")?.trim().orEmpty()
    } catch (_: Throwable) {
        ""
    }
}

private fun normalizeRole(value: String?): String {
    return when (value?.trim()?.lowercase()) {
        "customer" -> "user"
        "user" -> "user"
        else -> value?.trim()?.lowercase().orEmpty()
    }
}

private fun parseInt(value: String?): Int {
    return try {
        value?.trim()?.toInt() ?: 0
    } catch (_: Throwable) {
        0
    }
}
