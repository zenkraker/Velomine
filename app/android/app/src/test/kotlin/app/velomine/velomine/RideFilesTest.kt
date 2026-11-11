package app.velomine.velomine

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.util.zip.GZIPOutputStream
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

class RideFilesTest {
    private fun fitHeader(): ByteArray =
        byteArrayOf(14, 0x20, 0, 0, 0, 0, 0, 0, '.'.code.toByte(), 'F'.code.toByte(), 'I'.code.toByte(), 'T'.code.toByte(), 0, 0)

    private fun gzip(bytes: ByteArray): ByteArray {
        val out = ByteArrayOutputStream()
        GZIPOutputStream(out).use { it.write(bytes) }
        return out.toByteArray()
    }

    private val gpx = """<?xml version="1.0"?><gpx version="1.1"><trk></trk></gpx>""".toByteArray()
    private val tcx = """<?xml version="1.0"?><TrainingCenterDatabase></TrainingCenterDatabase>""".toByteArray()

    @Test
    fun RideFiles_ShouldRecogniseRideNames_WhenTheEndingIsFitGpxOrTcx() {
        for (name in listOf("a.fit", "B.GPX", "c.Tcx", "d.fit.gz", "e.GPX.GZ", "ride 2026-11-02.tcx.gz")) {
            assertTrue(RideFiles.looksLikeRideName(name), name)
        }
    }

    @Test
    fun RideFiles_ShouldRejectOtherNames_WhenTheNameIsNotARideFile() {
        for (name in listOf(null, "", "notes.txt", "photo.jpg", "settings.json", "x.gz", ".fit", "fit", "ride.zip", "ride.fit.bak")) {
            assertFalse(RideFiles.looksLikeRideName(name), name ?: "null")
        }
    }

    @Test
    fun RideFiles_ShouldRecogniseByContent_WhenTheNameSaysNothing() {
        assertTrue(RideFiles.isRideFile("download", fitHeader()))
        assertTrue(RideFiles.isRideFile("1234", gpx))
        assertTrue(RideFiles.isRideFile(null, tcx))
        assertTrue(RideFiles.isRideFile("content", "﻿\n  <gpx></gpx>".toByteArray()))
    }

    @Test
    fun RideFiles_ShouldLookInsideGzip_WhenTheNameSaysNothing() {
        assertTrue(RideFiles.isRideFile("attachment", gzip(gpx)))
        assertTrue(RideFiles.isRideFile("attachment", gzip(fitHeader())))
        assertFalse(RideFiles.isRideFile("attachment", gzip("just some words".toByteArray())))
    }

    @Test
    fun RideFiles_ShouldRejectAFile_WhenNeitherNameNorContentIsARide() {
        assertFalse(RideFiles.isRideFile("shopping.txt", "milk, eggs".toByteArray()))
        assertFalse(RideFiles.isRideFile("page", "<html><body>hi</body></html>".toByteArray()))
        assertFalse(RideFiles.isRideFile("photo", byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0xFF.toByte(), 0xE0.toByte())))
    }

    @Test
    fun RideFiles_ShouldRejectAnEmptyFile_WhenItHasARideName() {
        assertFalse(RideFiles.isRideFile("empty.fit", ByteArray(0)))
    }

    @Test
    fun RideFiles_ShouldGiveTheSameKey_WhenTheSameContentArrivesTwice() {
        val first = RideFiles.copy(ByteArrayInputStream(gpx), ByteArrayOutputStream())
        val second = RideFiles.copy(ByteArrayInputStream(gpx.copyOf()), ByteArrayOutputStream())

        assertEquals(first.sha256Hex, second.sha256Hex)
        assertEquals(RideFiles.contentKey(first.sha256Hex), RideFiles.contentKey(second.sha256Hex))
        assertEquals(64, first.sha256Hex.length)
    }

    @Test
    fun RideFiles_ShouldGiveAnotherKey_WhenTheContentDiffers() {
        val first = RideFiles.copy(ByteArrayInputStream(gpx), ByteArrayOutputStream())
        val other = RideFiles.copy(ByteArrayInputStream(tcx), ByteArrayOutputStream())

        assertNotEquals(first.sha256Hex, other.sha256Hex)
    }

    @Test
    fun RideFiles_ShouldKnowTheSha256_WhenCopyingAKnownText() {
        val copy = RideFiles.copy(ByteArrayInputStream("abc".toByteArray()), ByteArrayOutputStream())

        assertEquals("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", copy.sha256Hex)
    }

    @Test
    fun RideFiles_ShouldWriteEveryByteAndKeepTheHead_WhenCopying() {
        val data = ByteArray(10_000) { (it % 251).toByte() }
        val out = ByteArrayOutputStream()

        val copy = RideFiles.copy(ByteArrayInputStream(data), out)

        assertTrue(data.contentEquals(out.toByteArray()))
        assertEquals(10_000L, copy.size)
        assertEquals(RideFiles.HEAD_BYTES, copy.head.size)
        assertTrue(data.copyOf(RideFiles.HEAD_BYTES).contentEquals(copy.head))
    }

    @Test
    fun RideFiles_ShouldStopAndSayTooLarge_WhenTheFileRunsPastTheLimit() {
        val copy = RideFiles.copy(ByteArrayInputStream(ByteArray(5000)), ByteArrayOutputStream(), limit = 1000)

        assertTrue(copy.tooLarge)
    }
}
