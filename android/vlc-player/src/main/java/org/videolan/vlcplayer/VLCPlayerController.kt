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
    private val libVlc = LibVLC(appContext, listOf("--sub-text-scale=$subtitleScale"))

    private var currentUrl: Uri? = null
    private var player: MediaPlayer? = null
    private var surfaceView: SurfaceView? = null
    private var pendingPosition: Float? = null
    private var intentionalStop = false

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
        if (player != null && currentUrl == url) {
            play()
            return
        }

        unload()
        currentUrl = url
        position = preferences.getFloat(url.toString(), 0f).coerceIn(0f, 1f)
        pendingPosition = position
        status = PlayerStatus.Loading

        val newPlayer = MediaPlayer(libVlc)
        newPlayer.setEventListener(::onPlayerEvent)
        player = newPlayer
        attachSurfaceIfPossible()

        val media = Media(libVlc, url)
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
        intentionalStop = true
        player?.let { currentPlayer ->
            if (currentPlayer.vlcVout.areViewsAttached()) currentPlayer.vlcVout.detachViews()
            currentPlayer.stop()
            currentPlayer.setEventListener(null)
            currentPlayer.release()
        }
        player = null
        intentionalStop = false
        audioTracks.clear()
        subtitleTracks.clear()
    }

    override fun close() {
        unload()
        libVlc.release()
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

    private fun onPlayerEvent(event: MediaPlayer.Event) {
        val currentPlayer = player ?: return
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
            -> if (!intentionalStop) status = PlayerStatus.Finished
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

    private fun MutableList<PlayerTrack>.replaceWith(
        tracks: Array<out MediaPlayer.TrackDescription>,
    ) {
        clear()
        if (tracks.isNotEmpty() && tracks.none { it.id == DISABLED_TRACK_ID }) {
            add(PlayerTrack(DISABLED_TRACK_ID, appContext.getString(R.string.vlc_player_disable)))
        }
        addAll(tracks.map { PlayerTrack(it.id, it.name) })
    }

    private companion object {
        const val POSITIONS_STORE = "vlcPlayerPositions"
        const val DISABLED_TRACK_ID = -1
    }
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
