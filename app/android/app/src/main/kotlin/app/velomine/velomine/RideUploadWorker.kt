package app.velomine.velomine

import android.content.Context
import android.content.pm.ApplicationInfo
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

/**
 * Uploads finished local rides when the app is not open. It talks to the same endpoint as the in-app queue, using
 * the local ride id as the idempotency key, and keeps its progress in each ride's upload.json. It hands the file over
 * and records "processing": the app's queue follows the server's read to the end, so only one of the two polls.
 */
class RideUploadWorker(
    appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {
    private val debug: Boolean
        get() = (applicationContext.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    override fun doWork(): Result {
        val serverUrl = inputData.getString(KEY_SERVER_URL)?.trimEnd('/')
        if (serverUrl.isNullOrEmpty()) return Result.success()

        val store = RideStore(applicationContext)
        val tokens = SecureTokenStore(applicationContext)

        // Nothing ready to send: stop before refreshing. Every refresh rotates the token the open app also holds.
        if (store.list().none { it["state"] == "ready" && it["uploadState"] != "uploaded" }) {
            log("worker: no rides to upload")
            return Result.success()
        }

        if (tokens.read() == null) {
            log("worker: no refresh token")
            return Result.success()
        }
        val firstToken = refresh(serverUrl, tokens)
        if (firstToken.networkError) return Result.retry()
        if (firstToken.token == null) {
            log("worker: the saved session was refused")
            return Result.success()
        }

        var accessToken: String = firstToken.token ?: return Result.success()
        val user = currentUser(serverUrl, accessToken)
        if (user.networkError) return Result.retry()
        val accountId = user.id
        if (accountId == null) {
            log("worker: could not read the signed-in member")
            return Result.success()
        }

        // Claims rides recorded before account ids were kept, then keeps only this member's rides.
        val rides = store.list(claimFor = accountId).filter {
            it["state"] == "ready" && it["uploadState"] != "uploaded"
        }
        if (rides.isEmpty()) {
            log("worker: no rides to upload")
            return Result.success()
        }
        log("worker: ${rides.size} ride(s) to upload to $serverUrl for $accountId")

        var retry = false
        var signedOut = false

        for (ride in rides) {
            if (signedOut) break
            val id = ride["id"] as? String ?: continue
            val bytes = store.readFit(id)
            if (bytes == null || bytes.isEmpty()) {
                store.markUpload(id, "failed", error = "no_file")
                continue
            }

            val attempts = ((ride["uploadAttempts"] as? Number)?.toInt() ?: 0) + 1
            store.markUpload(id, "uploading", attempts = attempts)
            val result = upload(serverUrl, id, bytes, accessToken, tokens)
            accessToken = result.token
            if (result.signedOut) {
                signedOut = true
                store.markUpload(id, "failed", error = "sign_in", attempts = attempts)
                break
            }
            when (result.outcome) {
                // Uploaded: the server reads the file in the background and the app follows it to the end.
                "uploaded" -> store.markUpload(
                    id,
                    "processing",
                    serverRideId = result.serverRideId,
                    attempts = attempts,
                )
                "retry" -> {
                    retry = true
                    store.markUpload(id, "failed", error = result.error ?: "offline", attempts = attempts)
                }
                else -> store.markUpload(
                    id,
                    "failed",
                    error = result.error ?: "server_failed",
                    attempts = attempts,
                )
            }
        }

        return if (retry) Result.retry() else Result.success()
    }

    private data class UploadOutcome(
        val outcome: String,
        val token: String,
        val serverRideId: String? = null,
        val error: String? = null,
        val signedOut: Boolean = false,
    )

    private fun upload(
        serverUrl: String,
        localId: String,
        bytes: ByteArray,
        token: String,
        tokens: SecureTokenStore,
    ): UploadOutcome {
        var access = token
        var response = uploadFit(serverUrl, localId, bytes, access)

        if (response.code == 401) {
            val refreshed = refresh(serverUrl, tokens)
            if (refreshed.networkError) return UploadOutcome("retry", access, error = "offline")
            access = refreshed.token ?: return signedOut(token)
            response = uploadFit(serverUrl, localId, bytes, access)
        }

        if (response.networkError) return UploadOutcome("retry", access, error = "offline")
        if (response.code == 401) return signedOut(access)
        if (response.code !in 200..299) {
            return UploadOutcome(
                if (response.code >= 500) "retry" else "failed",
                access,
                error = "http_${response.code}",
            )
        }

        val serverRideId = try {
            JSONObject(response.body).optString("rideId")
        } catch (_: Exception) {
            ""
        }
        if (serverRideId.isEmpty()) {
            return UploadOutcome("failed", access, error = "server_failed")
        }

        // The server reads the file in the background. The app's own queue follows it to the end; the worker only
        // hands the file over, so the two do not poll and refresh at the same time.
        return UploadOutcome("uploaded", access, serverRideId)
    }

    private fun signedOut(token: String) = UploadOutcome("failed", token, signedOut = true)

    private data class RefreshOutcome(val token: String?, val networkError: Boolean = false)

    private data class UserOutcome(val id: String?, val networkError: Boolean = false)

    /** Who the token belongs to, so a worker left over from another sign-in never uploads their rides. */
    private fun currentUser(serverUrl: String, accessToken: String): UserOutcome {
        val response = request(
            "$serverUrl/api/v1/accounts/me",
            "GET",
            mapOf("Authorization" to "Bearer $accessToken"),
            null,
        )
        if (response.networkError) return UserOutcome(null, networkError = true)
        if (response.code !in 200..299) return UserOutcome(null)
        return try {
            UserOutcome(JSONObject(response.body).optString("id").ifEmpty { null })
        } catch (_: Exception) {
            UserOutcome(null)
        }
    }

    /** One rotation at a time: the app may be refreshing the same token while the worker runs. */
    private fun refresh(serverUrl: String, tokens: SecureTokenStore): RefreshOutcome {
        val locked = tokens.lock()
        try {
            // Read after the lock: the other writer may have left a newer token behind.
            val refreshToken = tokens.read() ?: return RefreshOutcome(null)
            val body = JSONObject().put("refreshToken", refreshToken).toString().toByteArray()
            val response = request(
                "$serverUrl/api/v1/accounts/refresh",
                "POST",
                mapOf("Content-Type" to "application/json"),
                body,
            )
            if (response.networkError) return RefreshOutcome(null, networkError = true)
            if (response.code == 401) return RefreshOutcome(null)
            if (response.code != 200) return RefreshOutcome(null, networkError = true)
            return try {
                val json = JSONObject(response.body)
                val access = json.optString("accessToken")
                val newRefresh = json.optString("refreshToken")
                if (newRefresh.isNotEmpty()) tokens.write(newRefresh)
                RefreshOutcome(access.ifEmpty { null })
            } catch (_: Exception) {
                RefreshOutcome(null)
            }
        } finally {
            if (locked) tokens.unlock()
        }
    }

    private fun uploadFit(
        serverUrl: String,
        localId: String,
        bytes: ByteArray,
        token: String,
    ): HttpResult {
        val boundary = "----Velomine${System.nanoTime()}"
        val prefix = "--$boundary\r\n" +
            "Content-Disposition: form-data; name=\"file\"; filename=\"ride.fit\"\r\n" +
            "Content-Type: application/octet-stream\r\n\r\n"
        val suffix = "\r\n--$boundary--\r\n"
        val body = ByteArrayOutputStream().apply {
            write(prefix.toByteArray())
            write(bytes)
            write(suffix.toByteArray())
        }.toByteArray()

        return request(
            "$serverUrl/api/v1/rides/uploads",
            "POST",
            mapOf(
                "Authorization" to "Bearer $token",
                "Idempotency-Key" to localId,
                "Content-Type" to "multipart/form-data; boundary=$boundary",
            ),
            body,
        )
    }

    private data class HttpResult(
        val code: Int,
        val body: String,
        val networkError: Boolean = false,
    )

    private fun request(
        url: String,
        method: String,
        headers: Map<String, String>,
        body: ByteArray?,
    ): HttpResult {
        var connection: HttpURLConnection? = null
        return try {
            connection = URL(url).openConnection() as HttpURLConnection
            connection.requestMethod = method
            connection.connectTimeout = CONNECT_TIMEOUT_MS
            connection.readTimeout = READ_TIMEOUT_MS
            headers.forEach { (key, value) -> connection.setRequestProperty(key, value) }
            if (body != null) {
                connection.doOutput = true
                connection.setFixedLengthStreamingMode(body.size)
                connection.outputStream.use { it.write(body) }
            }
            val code = connection.responseCode
            val stream = if (code in 200..299) connection.inputStream else connection.errorStream
            val text = stream?.bufferedReader()?.use { it.readText() } ?: ""
            HttpResult(code, text)
        } catch (_: IOException) {
            HttpResult(0, "", networkError = true)
        } catch (_: Exception) {
            HttpResult(0, "", networkError = true)
        } finally {
            connection?.disconnect()
        }
    }

    private fun log(message: String) {
        if (debug) Log.d(TAG, message)
    }

    companion object {
        const val KEY_SERVER_URL = "serverUrl"
        private const val TAG = "VelomineRecorder"
        private const val CONNECT_TIMEOUT_MS = 15_000
        private const val READ_TIMEOUT_MS = 30_000
    }
}
