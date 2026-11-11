package app.velomine.velomine

import java.io.ByteArrayInputStream
import java.io.InputStream
import java.io.OutputStream
import java.security.MessageDigest
import java.util.zip.GZIPInputStream

/**
 * Telling a ride file from anything else, and naming one by what is in it.
 *
 * Other apps hand over ride files with unreliable types (`application/octet-stream`, `text/xml`, none at all), so the
 * file name decides first and the first bytes decide when the name does not: a FIT header, or the opening tag of a
 * GPX or TCX document, also inside a gzip.
 */
object RideFiles {
    /** The server refuses a ride file bigger than this, so there is no point keeping one. */
    const val MAX_BYTES = 30L * 1024 * 1024

    /** How much of a file is looked at to recognise it. */
    const val HEAD_BYTES = 4096

    private val extensions = listOf("fit", "gpx", "tcx")

    /** `.fit`, `.gpx` or `.tcx`, or the same with `.gz`, in any letter case, with a name before the dot. */
    fun looksLikeRideName(name: String?): Boolean {
        var lower = (name ?: return false).trim().lowercase()
        if (lower.endsWith(".gz")) lower = lower.removeSuffix(".gz")
        return extensions.any { lower.length > it.length + 1 && lower.endsWith(".$it") }
    }

    /** Whether the first bytes of a file are a FIT header, or a GPX or TCX document, gzipped or not. */
    fun looksLikeRideContent(head: ByteArray): Boolean {
        if (isGzip(head)) return plainLooksLikeRide(gunzipPrefix(head))
        return plainLooksLikeRide(head)
    }

    /** A ride file by its name, or failing that by its content. An empty file is never one. */
    fun isRideFile(name: String?, head: ByteArray): Boolean {
        if (head.isEmpty()) return false
        if (looksLikeRideName(name)) return true
        return looksLikeRideContent(head)
    }

    /**
     * The key that stands for this content on the phone and on the server: the same file shared twice gets the same
     * key, so it is one ride however often it arrives. It is also the local ride's id.
     */
    fun contentKey(sha256Hex: String): String = "file-$sha256Hex"

    /** A copy of a stream with its size, its SHA-256 and its first bytes, made in one pass. */
    class Copy(val sha256Hex: String, val size: Long, val head: ByteArray, val tooLarge: Boolean)

    /** Copies [input] to [output], stopping with [Copy.tooLarge] set when it runs past [limit] bytes. */
    fun copy(input: InputStream, output: OutputStream, limit: Long = MAX_BYTES): Copy {
        val digest = MessageDigest.getInstance("SHA-256")
        val head = java.io.ByteArrayOutputStream()
        val buffer = ByteArray(64 * 1024)
        var size = 0L
        while (true) {
            val read = input.read(buffer)
            if (read < 0) break
            size += read
            if (size > limit) return Copy("", size, head.toByteArray(), tooLarge = true)
            digest.update(buffer, 0, read)
            output.write(buffer, 0, read)
            if (head.size() < HEAD_BYTES) head.write(buffer, 0, minOf(read, HEAD_BYTES - head.size()))
        }
        return Copy(digest.digest().joinToString("") { "%02x".format(it) }, size, head.toByteArray(), tooLarge = false)
    }

    private fun isGzip(bytes: ByteArray) =
        bytes.size >= 2 && bytes[0] == 0x1f.toByte() && bytes[1] == 0x8b.toByte()

    private fun plainLooksLikeRide(bytes: ByteArray): Boolean = isFit(bytes) || isRideXml(bytes)

    /** A FIT file starts with a 12 or 14 byte header whose bytes 8 to 11 spell ".FIT". */
    private fun isFit(bytes: ByteArray): Boolean =
        bytes.size >= 12 &&
            (bytes[0].toInt() == 12 || bytes[0].toInt() == 14) &&
            bytes[8] == '.'.code.toByte() &&
            bytes[9] == 'F'.code.toByte() &&
            bytes[10] == 'I'.code.toByte() &&
            bytes[11] == 'T'.code.toByte()

    private fun isRideXml(bytes: ByteArray): Boolean {
        val text = String(bytes, Charsets.UTF_8).trimStart('﻿', ' ', '\t', '\r', '\n')
        if (!text.startsWith("<")) return false
        return text.contains("<gpx", ignoreCase = true) ||
            text.contains("<TrainingCenterDatabase", ignoreCase = true)
    }

    /** The first part of what a gzip holds. The head of a file is cut short, so the stream ending early is expected. */
    private fun gunzipPrefix(head: ByteArray, limit: Int = HEAD_BYTES): ByteArray {
        val out = java.io.ByteArrayOutputStream()
        try {
            GZIPInputStream(ByteArrayInputStream(head)).use { stream ->
                val buffer = ByteArray(1024)
                while (out.size() < limit) {
                    val read = stream.read(buffer)
                    if (read < 0) break
                    out.write(buffer, 0, read)
                }
            }
        } catch (_: Exception) {
            // Cut off in the middle of the gzip: what was read so far is enough to recognise it.
        }
        return out.toByteArray()
    }
}
