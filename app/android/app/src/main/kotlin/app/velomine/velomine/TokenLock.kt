package app.velomine.velomine

import java.io.File
import java.io.IOException

/**
 * One writer at a time holds [file], created with `createNewFile` so the check and the claim are one atomic step.
 *
 * The app and the background upload worker both rotate the same single-use refresh token; rotating it twice at once
 * makes the server treat the second one as a stolen token and end the session. Both take this lock around the call.
 *
 * The wait is short and the lock is stale after a minute: a sign-in must never hang behind a crashed writer.
 */
class TokenLock(
    private val file: File,
    private val waitMs: Long = WAIT_MS,
    private val staleMs: Long = STALE_MS,
) {
    /**
     * One attempt, no waiting, so it is safe to call from the main thread: the app retries between network-free
     * pauses instead of blocking the UI.
     */
    fun tryAcquire(): Boolean = try {
        if (file.createNewFile()) {
            true
        } else if (System.currentTimeMillis() - file.lastModified() > staleMs) {
            // Left behind by a crash or a killed process.
            file.delete()
            file.createNewFile()
        } else {
            false
        }
    } catch (_: IOException) {
        // A read-only folder: carry on without the lock rather than failing the sign-in.
        false
    }

    /** True when this caller now holds the lock; false after [waitMs] of someone else holding it. */
    fun acquire(): Boolean {
        val deadline = System.currentTimeMillis() + waitMs
        while (true) {
            if (tryAcquire()) return true
            if (System.currentTimeMillis() >= deadline) return false
            try {
                Thread.sleep(RETRY_MS)
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt()
                return false
            }
        }
    }

    fun release() {
        runCatching { file.delete() }
    }

    companion object {
        const val WAIT_MS = 5_000L
        const val STALE_MS = 60_000L
        private const val RETRY_MS = 50L
    }
}
