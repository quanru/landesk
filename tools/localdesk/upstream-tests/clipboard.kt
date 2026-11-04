// Android Parcel / ClipboardManager / protobuf doubles. The actual production
// rustUpdateClipboard method is inserted verbatim by the runner; this is a JVM
// regression test, not an Android Binder integration test.
annotation class Keep
enum class ClipboardFormat { Text, Html, ImageRgba, ImagePng }
class Content(private val text: String) { fun toByteArray() = text.toByteArray() }
class Clip(val format: ClipboardFormat, val content: Content)
class MultiClipboards(private val clips: List<Clip>) {
    fun getClipboardsList() = clips
    companion object {
        var pending = MultiClipboards(emptyList())
        fun parseFrom(bytes: ByteArray) = pending
    }
}
class ClipDescription(val label: String, val types: Array<String>) {
    companion object {
        const val MIMETYPE_TEXT_PLAIN = "text/plain"
        const val MIMETYPE_TEXT_HTML = "text/html"
    }
}
class ClipData(val description: ClipDescription, val item: Item) {
    class Item(val text: String, val html: String? = null)
    fun writeToParcel(parcel: Parcel, flags: Int) { parcel.written = true }
}
class Parcel {
    var written = false
    fun dataSize(): Int { check(written); return nextSize }
    fun recycle() { recycled++ }
    companion object {
        var nextSize = 64
        var recycled = 0
        fun obtain() = Parcel()
    }
}
class ClipboardManager {
    var shouldThrow = false
    var writes = 0
    var primary: ClipData? = null
    fun setPrimaryClip(clip: ClipData) {
        if (shouldThrow) throw RuntimeException("Binder transaction failed")
        primary = clip
        writes++
    }
}
object Log {
    fun e(tag: String, message: String, e: Exception? = null) {}
    fun w(tag: String, message: String) {}
}
class ClipboardHarness(private val clipboardManager: ClipboardManager) {
    private val logTag = "RdClipboardManager"
    private var lastUpdatedClipData: ClipData? = null
    fun last() = lastUpdatedClipData
    // PRODUCTION
}

fun main() {
    val manager = ClipboardManager()
    val harness = ClipboardHarness(manager)
    fun update(text: String = "hello", html: String? = null) {
        val clips = mutableListOf(Clip(ClipboardFormat.Text, Content(text)))
        if (html != null) clips.add(Clip(ClipboardFormat.Html, Content(html)))
        MultiClipboards.pending = MultiClipboards(clips)
        harness.rustUpdateClipboard(byteArrayOf())
    }
    update()
    check(manager.writes == 1 && harness.last() === manager.primary)
    val first = harness.last()
    Parcel.nextSize = 800 * 1024 + 1
    update("big", "<p>large HTML counts too</p>")
    check(manager.writes == 1 && harness.last() === first)
    check(Parcel.recycled == 2)
    Parcel.nextSize = 800 * 1024
    update("at the limit")
    check(manager.writes == 2 && harness.last() === manager.primary)
    val beforeFailure = harness.last()
    manager.shouldThrow = true
    Parcel.nextSize = 64
    update("failed write") // Direct and wrapped Binder failures must not escape.
    check(manager.writes == 2 && harness.last() === beforeFailure)
    check(Parcel.recycled == 4)
    manager.shouldThrow = false
    update("retry")
    check(manager.writes == 3 && harness.last() === manager.primary)
    check(Parcel.recycled == 5)
    println("PASS: normal write, oversize rejection, boundary, Binder failure, retry; Parcels recycled")
}
