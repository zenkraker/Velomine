package app.velomine.velomine

import java.io.File
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class TokenLockTest {
    @Test
    fun TokenLock_ShouldLetOnlyOneWriterIn_WhenBothAskAtOnce() {
        val file = File(createTempDir(), "token.lock")
        val first = TokenLock(file)
        val second = TokenLock(file)

        assertTrue(first.tryAcquire())
        assertFalse(second.tryAcquire())

        first.release()
        assertTrue(second.tryAcquire())
        second.release()
    }

    @Test
    fun TokenLock_ShouldTakeOverTheLock_WhenTheWriterCrashed() {
        val file = File(createTempDir(), "token.lock")
        assertTrue(file.createNewFile())
        file.setLastModified(System.currentTimeMillis() - 2 * 60_000)

        val lock = TokenLock(file)

        assertTrue(lock.tryAcquire())
        lock.release()
        assertFalse(file.exists())
    }

    @Test
    fun TokenLock_ShouldGiveUp_WhenAnotherWriterKeepsItPastTheWait() {
        val file = File(createTempDir(), "token.lock")
        val held = TokenLock(file)
        assertTrue(held.tryAcquire())

        val waiting = TokenLock(file, waitMs = 100)

        assertFalse(waiting.acquire())
        held.release()
        assertTrue(waiting.tryAcquire())
        waiting.release()
    }

    private fun createTempDir(): File = kotlin.io.path.createTempDirectory("velomine-lock-").toFile()
}
