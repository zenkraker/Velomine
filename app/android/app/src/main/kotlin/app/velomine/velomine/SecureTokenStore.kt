package app.velomine.velomine

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Keeps the refresh token encrypted with a key that never leaves the Android Keystore.
 *
 * The file lives in noBackupFilesDir: it is device-bound, so it is not copied to a new phone by a backup. If the
 * key is invalidated (for example by a lock-screen change), the token is dropped and the member signs in again.
 */
class SecureTokenStore(context: Context) {
    private val file = File(context.noBackupFilesDir, "velomine-token")

    @Synchronized
    fun read(): String? {
        if (!file.exists()) return null
        return try {
            val packed = Base64.decode(file.readText(), Base64.NO_WRAP)
            val input = DataInputStream(ByteArrayInputStream(packed))
            val ivLength = input.readInt()
            require(ivLength in 1..32) { "Unexpected IV length." }
            val iv = ByteArray(ivLength).also { input.readFully(it) }
            val ciphertext = input.readBytes()

            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, iv))
            String(cipher.doFinal(ciphertext), Charsets.UTF_8)
        } catch (e: Exception) {
            Log.w(TAG, "Could not read the token; clearing it.", e)
            reset()
            null
        }
    }

    @Synchronized
    fun write(token: String): Boolean = try {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val ciphertext = cipher.doFinal(token.toByteArray(Charsets.UTF_8))

        val bytes = ByteArrayOutputStream()
        DataOutputStream(bytes).use {
            it.writeInt(cipher.iv.size)
            it.write(cipher.iv)
            it.write(ciphertext)
        }
        file.writeText(Base64.encodeToString(bytes.toByteArray(), Base64.NO_WRAP))
        Log.i(TAG, "Refresh token written.")
        true
    } catch (e: Exception) {
        Log.w(TAG, "Could not write the token.", e)
        reset()
        false
    }

    @Synchronized
    fun clear() {
        runCatching { file.delete() }
    }

    /// Drops both the ciphertext and the key, so a new key can be made on the next write.
    private fun reset() {
        runCatching { file.delete() }
        runCatching {
            KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }.deleteEntry(ALIAS)
        }
    }

    private fun key(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        (keyStore.getEntry(ALIAS, null) as? KeyStore.SecretKeyEntry)?.let {
            return it.secretKey
        }

        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        generator.init(
            KeyGenParameterSpec.Builder(
                ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build(),
        )
        generator.generateKey()
        return (keyStore.getEntry(ALIAS, null) as KeyStore.SecretKeyEntry).secretKey
    }

    private companion object {
        const val TAG = "SecureTokenStore"
        const val ANDROID_KEYSTORE = "AndroidKeyStore"
        const val ALIAS = "velomine_token_key"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
    }
}
