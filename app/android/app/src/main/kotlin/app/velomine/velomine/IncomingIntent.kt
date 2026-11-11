package app.velomine.velomine

import android.content.Intent
import android.net.Uri
import android.os.Build

/** Reads the files out of what other apps send us: Share (one or several) and Open with. */
object IncomingIntent {
    fun isIncoming(intent: Intent?): Boolean = when (intent?.action) {
        Intent.ACTION_SEND, Intent.ACTION_SEND_MULTIPLE, Intent.ACTION_VIEW -> true
        else -> false
    }

    /** Every file address in the intent, each once, in the order they came. */
    fun uris(intent: Intent?): List<Uri> {
        if (intent == null || !isIncoming(intent)) return emptyList()
        val found = linkedSetOf<Uri>()
        when (intent.action) {
            Intent.ACTION_VIEW -> intent.data?.let { found += it }
            Intent.ACTION_SEND -> stream(intent)?.let { found += it }
            Intent.ACTION_SEND_MULTIPLE -> found += streams(intent)
        }
        // Some apps put the files only in the clip data.
        val clip = intent.clipData
        if (clip != null) {
            for (i in 0 until clip.itemCount) clip.getItemAt(i).uri?.let { found += it }
        }
        return found.toList()
    }

    @Suppress("DEPRECATION")
    private fun stream(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    @Suppress("DEPRECATION")
    private fun streams(intent: Intent): List<Uri> =
        (
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
            }
            ) ?: emptyList()
}
