package com.example.delvery

import android.content.Context
import android.content.SharedPreferences

private const val FLUTTER_SHARED_PREFS_NAME = "FlutterSharedPreferences"
private const val FLUTTER_PREFIX = "flutter."

data class VoiceCallDeliveryCheck(
    val allowed: Boolean,
    val reason: String,
    val localDriverId: Int,
    val localDriverName: String,
    val localLoggedIn: Boolean,
    val callerId: Int,
    val callerRole: String,
    val calleeId: Int,
    val calleeRole: String,
)

fun Context.checkIncomingVoiceCallTarget(data: Map<String, String>): VoiceCallDeliveryCheck {
    val prefs = getSharedPreferences(FLUTTER_SHARED_PREFS_NAME, Context.MODE_PRIVATE)
    val localDriverId = prefs.readFlutterInt("driver_remote_id")
    val localDriverName = prefs.readFlutterString("driver_name")
    val localLoggedIn = prefs.readFlutterBool("driver_logged_in")
    val callerId = parseInt(data["caller_id"])
    val callerRole = data["caller_role"]?.trim()?.lowercase().orEmpty()
    val calleeId = parseInt(data["callee_id"])
    val calleeRole = normalizeRole(data["callee_role"])

    if (!localLoggedIn) {
        return VoiceCallDeliveryCheck(
            allowed = false,
            reason = "driver_not_logged_in",
            localDriverId = localDriverId,
            localDriverName = localDriverName,
            localLoggedIn = localLoggedIn,
            callerId = callerId,
            callerRole = callerRole,
            calleeId = calleeId,
            calleeRole = calleeRole,
        )
    }

    if (localDriverId <= 0) {
        return VoiceCallDeliveryCheck(
            allowed = false,
            reason = "local_driver_missing",
            localDriverId = localDriverId,
            localDriverName = localDriverName,
            localLoggedIn = localLoggedIn,
            callerId = callerId,
            callerRole = callerRole,
            calleeId = calleeId,
            calleeRole = calleeRole,
        )
    }

    if (calleeRole != "driver") {
        return VoiceCallDeliveryCheck(
            allowed = false,
            reason = "callee_role_mismatch",
            localDriverId = localDriverId,
            localDriverName = localDriverName,
            localLoggedIn = localLoggedIn,
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
            localDriverId = localDriverId,
            localDriverName = localDriverName,
            localLoggedIn = localLoggedIn,
            callerId = callerId,
            callerRole = callerRole,
            calleeId = calleeId,
            calleeRole = calleeRole,
        )
    }

    if (calleeId != localDriverId) {
        return VoiceCallDeliveryCheck(
            allowed = false,
            reason = "callee_id_mismatch",
            localDriverId = localDriverId,
            localDriverName = localDriverName,
            localLoggedIn = localLoggedIn,
            callerId = callerId,
            callerRole = callerRole,
            calleeId = calleeId,
            calleeRole = calleeRole,
        )
    }

    if (callerId > 0 && callerId == localDriverId) {
        return VoiceCallDeliveryCheck(
            allowed = false,
            reason = "caller_matches_local_driver",
            localDriverId = localDriverId,
            localDriverName = localDriverName,
            localLoggedIn = localLoggedIn,
            callerId = callerId,
            callerRole = callerRole,
            calleeId = calleeId,
            calleeRole = calleeRole,
        )
    }

    return VoiceCallDeliveryCheck(
        allowed = true,
        reason = "matched",
        localDriverId = localDriverId,
        localDriverName = localDriverName,
        localLoggedIn = localLoggedIn,
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

private fun SharedPreferences.readFlutterBool(key: String): Boolean {
    val storedKey = "$FLUTTER_PREFIX$key"
    return try {
        getBoolean(storedKey, false)
    } catch (_: Throwable) {
        false
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
