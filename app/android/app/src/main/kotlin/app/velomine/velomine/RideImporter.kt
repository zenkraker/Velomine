package app.velomine.velomine

import android.content.ContentResolver
import android.net.Uri
import android.provider.OpenableColumns
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

/** How a batch of received files went. */
class ImportOutcome(
    val added: Int,
    val alreadyHere: Int,
    /** The names of files that are not ride files (or are too big), for the message to the member. */
    val rejected: List<String>,
)

/**
 * "Import these files": copies each one into the app's own storage straight away (the sender's permission to a shared
 * file is only temporary) and keeps it as a ready ride, which the upload queue then sends like a recorded one.
 *
 * Share and Open with call it today; reading a plugged-in bike computer can hand it the same kind of files later.
 */
class RideImporter(
    private val resolver: ContentResolver,
    private val store: RideStore,
) {
    fun import(uris: List<Uri>): ImportOutcome {
        var added = 0
        var alreadyHere = 0
        val rejected = mutableListOf<String>()
        for (uri in uris) {
            val name = displayName(uri)
            val opened = try {
                resolver.openInputStream(uri)
            } catch (_: Exception) {
                null
            }
            if (opened == null) {
                rejected += name ?: ""
                continue
            }
            val outcome = opened.use { importStream(name, it) }
            when (outcome) {
                Result.ADDED -> added++
                Result.ALREADY_HERE -> alreadyHere++
                Result.REJECTED -> rejected += name ?: ""
            }
        }
        return ImportOutcome(added, alreadyHere, rejected)
    }

    enum class Result { ADDED, ALREADY_HERE, REJECTED }

    /** One file: copied once, hashed on the way, then kept, recognised as already here, or thrown away. */
    fun importStream(name: String?, input: InputStream): Result {
        val temporary = store.newTemporaryFile()
        try {
            val copy = FileOutputStream(temporary).use { RideFiles.copy(input, it) }
            if (copy.tooLarge || !RideFiles.isRideFile(name, copy.head)) return Result.REJECTED
            val id = RideFiles.contentKey(copy.sha256Hex)
            return if (store.addFile(id, temporary, name ?: "ride")) Result.ADDED else Result.ALREADY_HERE
        } catch (_: Exception) {
            return Result.REJECTED
        } finally {
            // Kept files were moved; anything left over was not a ride.
            temporary.delete()
        }
    }

    private fun displayName(uri: Uri): String? {
        if (uri.scheme == ContentResolver.SCHEME_CONTENT) {
            try {
                resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val name = cursor.getString(0)
                        if (!name.isNullOrBlank()) return name
                    }
                }
            } catch (_: Exception) {
                // Some providers refuse the query; the last part of the address is the next best name.
            }
        }
        return uri.lastPathSegment?.let { File(it).name }?.takeIf { it.isNotBlank() }
    }
}

/**
 * What came in since the app last looked. The app asks for it when it starts and when told more arrived, so a file
 * shared while the app was not running is not lost.
 */
object IncomingFiles {
    private val lock = Any()
    private var added = 0
    private var alreadyHere = 0
    private val rejected = mutableListOf<String>()

    fun record(outcome: ImportOutcome) = synchronized(lock) {
        added += outcome.added
        alreadyHere += outcome.alreadyHere
        rejected += outcome.rejected
    }

    /** What is waiting, left in place. Null when nothing is. */
    fun peek(): Map<String, Any?>? = synchronized(lock) { snapshot() }

    /** What is waiting, cleared. Null when nothing is. */
    fun take(): Map<String, Any?>? = synchronized(lock) {
        val result = snapshot()
        added = 0
        alreadyHere = 0
        rejected.clear()
        result
    }

    private fun snapshot(): Map<String, Any?>? {
        if (added == 0 && alreadyHere == 0 && rejected.isEmpty()) return null
        return mapOf(
            "added" to added,
            "alreadyHere" to alreadyHere,
            "rejected" to rejected.toList(),
        )
    }
}
