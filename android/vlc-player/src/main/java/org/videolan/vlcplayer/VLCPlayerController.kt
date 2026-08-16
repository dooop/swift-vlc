package org.videolan.vlcplayer

import android.content.Context
import android.net.Uri
import android.view.SurfaceView
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import org.videolan.libvlc.LibVLC
import org.videolan.libvlc.Media
import org.videolan.libvlc.MediaPlayer

internal enum class PlayerStatus {
    Loading,
    Playing,
    Paused,
    Finished,
    Error,
}

internal data class PlayerTrack(
    val id: Int,
    val name: String,
)

internal class VLCPlayerController(
    context: Context,
    subtitleScale: Int,
) : AutoCloseable {
    private val appContext = context.applicationContext
    private val preferences = appContext.getSharedPreferences(POSITIONS_STORE, Context.MODE_PRIVATE)

    // LibVLC construction touches the native library directly and can fail with an
    // UnsatisfiedLinkError (missing/incompatible .so) or an IllegalStateException, neither of
    // which the app can prevent — surface it as a player error instead of crashing.
    private val libVlc: LibVLC? =
        try {
            LibVLC(appContext, mutableListOf("--sub-text-scale=$subtitleScale"))
        } catch (e: Throwable) {
            null
        }

    private var currentUrl: Uri? = null
    private var player: MediaPlayer? = null
    private var surfaceView: SurfaceView? = null
    private var pendingPosition: Float? = null

    var status by mutableStateOf(PlayerStatus.Loading)
        private set
    var position by mutableFloatStateOf(0f)
        private set
    var time by mutableLongStateOf(0L)
        private set
    var length by mutableLongStateOf(0L)
        private set
    var selectedAudioTrack by mutableStateOf<Int?>(null)
        private set
    var selectedSubtitleTrack by mutableStateOf<Int?>(null)
        private set

    val audioTracks = mutableStateListOf<PlayerTrack>()
    val subtitleTracks = mutableStateListOf<PlayerTrack>()

    val isPlaying: Boolean
        get() = status == PlayerStatus.Playing

    fun start(url: Uri) {
        val vlc = libVlc
        if (vlc == null) {
            status = PlayerStatus.Error
            return
        }

        if (player != null && currentUrl == url) {
            play()
            return
        }

        unload()
        currentUrl = url
        position = preferences.getFloat(url.toString(), 0f).coerceIn(0f, 1f)
        pendingPosition = position
        status = PlayerStatus.Loading

        val newPlayer = MediaPlayer(vlc)
        newPlayer.setEventListener { event -> onPlayerEvent(newPlayer, event) }
        player = newPlayer
        attachSurfaceIfPossible()

        val media = Media(vlc, url)
        media.setHWDecoderEnabled(true, false)
        newPlayer.media = media
        media.release()
        newPlayer.play()
    }

    fun play() {
        player?.play()
    }

    fun pause() {
        player?.takeIf { it.isPlaying }?.pause()
    }

    fun toggle() {
        when (status) {
            PlayerStatus.Finished, PlayerStatus.Error -> restart()
            PlayerStatus.Playing -> pause()
            else -> play()
        }
    }

    fun restart() {
        val url = currentUrl ?: return
        unload(savePosition = false)
        position = 0f
        preferences.edit().putFloat(url.toString(), 0f).apply()
        start(url)
    }

    fun seekTo(newPosition: Float) {
        val normalized = newPosition.coerceIn(0f, 1f)
        position = normalized
        time = (length * normalized).toLong()
        player?.position = normalized
    }

    fun selectAudioTrack(id: Int) {
        if (player?.setAudioTrack(id) == true) {
            selectedAudioTrack = id
        }
    }

    fun selectSubtitleTrack(id: Int) {
        if (player?.setSpuTrack(id) == true) {
            selectedSubtitleTrack = id
        }
    }

    fun attach(surface: SurfaceView) {
        if (surfaceView === surface) return
        detachSurface()
        surfaceView = surface
        attachSurfaceIfPossible()
    }

    fun detach(surface: SurfaceView) {
        if (surfaceView !== surface) return
        detachSurface()
        surfaceView = null
    }

    fun unload(savePosition: Boolean = true) {
        if (savePosition) savePosition()
        player?.let { currentPlayer ->
            if (currentPlayer.vlcVout.areViewsAttached()) currentPlayer.vlcVout.detachViews()
            currentPlayer.setEventListener(null)
            currentPlayer.stop()
            currentPlayer.release()
        }
        player = null
        audioTracks.clear()
        subtitleTracks.clear()
    }

    override fun close() {
        unload()
        libVlc?.release()
    }

    private fun attachSurfaceIfPossible() {
        val currentPlayer = player ?: return
        val surface = surfaceView ?: return
        if (currentPlayer.vlcVout.areViewsAttached()) currentPlayer.vlcVout.detachViews()
        currentPlayer.vlcVout.setVideoView(surface)
        currentPlayer.vlcVout.attachViews()
    }

    private fun detachSurface() {
        player?.vlcVout?.let { output ->
            if (output.areViewsAttached()) output.detachViews()
        }
    }

    private fun savePosition() {
        val url = currentUrl ?: return
        preferences.edit().putFloat(url.toString(), position.coerceIn(0f, 1f)).apply()
    }

    /**
     * `source` is the exact [MediaPlayer] this callback was registered on. Events are delivered
     * asynchronously off the calling thread, so by the time one arrives, [player] may already have
     * been unloaded or replaced (e.g. during [restart]). Comparing against the live [player] instead
     * of a boolean flag discards such stale events regardless of delivery timing.
     */
    private fun onPlayerEvent(
        source: MediaPlayer,
        event: MediaPlayer.Event,
    ) {
        val currentPlayer = player?.takeIf { it === source } ?: return
        when (event.type) {
            MediaPlayer.Event.Opening -> status = PlayerStatus.Loading
            MediaPlayer.Event.Buffering -> {
                status = if (currentPlayer.isPlaying) PlayerStatus.Playing else PlayerStatus.Loading
            }
            MediaPlayer.Event.Playing -> {
                status = PlayerStatus.Playing
                pendingPosition?.let {
                    currentPlayer.position = it
                    pendingPosition = null
                }
                updateTracks()
            }
            MediaPlayer.Event.Paused -> status = PlayerStatus.Paused
            MediaPlayer.Event.Stopped,
            MediaPlayer.Event.EndReached,
            -> status = PlayerStatus.Finished
            MediaPlayer.Event.EncounteredError -> status = PlayerStatus.Error
            MediaPlayer.Event.TimeChanged -> {
                time = event.timeChanged.coerceAtLeast(0L)
                if (length > 0) position = (time.toFloat() / length).coerceIn(0f, 1f)
            }
            MediaPlayer.Event.PositionChanged -> position = event.positionChanged.coerceIn(0f, 1f)
            MediaPlayer.Event.LengthChanged -> length = event.lengthChanged.coerceAtLeast(0L)
            MediaPlayer.Event.ESAdded,
            MediaPlayer.Event.ESDeleted,
            MediaPlayer.Event.ESSelected,
            -> updateTracks()
        }
    }

    private fun updateTracks() {
        val currentPlayer = player ?: return
        selectedAudioTrack = currentPlayer.audioTrack
        selectedSubtitleTrack = currentPlayer.spuTrack
        audioTracks.replaceWith(currentPlayer.audioTracks.orEmpty())
        subtitleTracks.replaceWith(currentPlayer.spuTracks.orEmpty())
    }

    private fun MutableList<PlayerTrack>.replaceWith(tracks: Array<out MediaPlayer.TrackDescription>) {
        val incoming = tracks.map { PlayerTrack(it.id, it.name) }
        val disabledLabel = appContext.getString(R.string.vlc_player_disable)
        clear()
        addAll(buildTrackList(incoming, DISABLED_TRACK_ID, disabledLabel))
    }

    private companion object {
        const val POSITIONS_STORE = "vlcPlayerPositions"
        const val DISABLED_TRACK_ID = -1
    }
}

/** Prepends a "disable" placeholder to [tracks], unless one is already present or the list is empty. */
internal fun buildTrackList(
    tracks: List<PlayerTrack>,
    disabledId: Int,
    disabledLabel: String,
): List<PlayerTrack> {
    if (tracks.isEmpty() || tracks.any { it.id == disabledId }) return tracks
    return listOf(PlayerTrack(disabledId, disabledLabel)) + tracks
}

internal fun formatPlayerTime(milliseconds: Long): String {
    val totalSeconds = (kotlin.math.abs(milliseconds) / 1_000L)
    val hours = totalSeconds / 3_600L
    val minutes = (totalSeconds % 3_600L) / 60L
    val seconds = totalSeconds % 60L
    val prefix = if (milliseconds < 0L) "-" else ""
    return if (hours > 0L) {
        "$prefix%02d:%02d:%02d".format(hours, minutes, seconds)
    } else {
        "$prefix%02d:%02d".format(minutes, seconds)
    }
}
