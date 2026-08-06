package de.doop.vlcplayer

import android.net.Uri
import android.view.SurfaceView
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.filled.Subtitles
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import kotlinx.coroutines.delay

/**
 * A self-contained LibVLC player matching the SwiftUI `VLCPlayer(url:)` experience.
 *
 * The player owns its LibVLC instance, resumes the last position for each URI, reacts to the host
 * lifecycle, and supplies play/pause/restart, seeking, time labels, and track selection controls.
 */
@Composable
public fun VLCPlayer(
    url: Uri,
    modifier: Modifier = Modifier,
    subtitleScale: Int = 100,
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val hostView = LocalView.current
    val controller = remember(context.applicationContext, subtitleScale) {
        VLCPlayerController(context, subtitleScale)
    }
    var controlsVisible by remember { mutableStateOf(true) }
    var interaction by remember { mutableIntStateOf(0) }
    var trackDialog by remember { mutableStateOf<TrackDialog?>(null) }

    fun showControls() {
        controlsVisible = true
        interaction++
    }

    LaunchedEffect(url) {
        controller.start(url)
        showControls()
    }

    LaunchedEffect(controller.status, interaction) {
        hostView.keepScreenOn = controller.isPlaying
        if (controller.isPlaying) {
            delay(CONTROL_HIDE_DELAY_MILLIS)
            controlsVisible = false
        } else {
            controlsVisible = true
        }
    }

    DisposableEffect(lifecycleOwner, url) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_RESUME -> controller.start(url)
                Lifecycle.Event.ON_PAUSE -> controller.pause()
                Lifecycle.Event.ON_STOP -> controller.unload()
                else -> Unit
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    DisposableEffect(controller) {
        onDispose {
            hostView.keepScreenOn = false
            controller.close()
        }
    }

    Box(modifier = modifier.background(Color.Black)) {
        VideoSurface(
            controller = controller,
            modifier = Modifier.fillMaxSize(),
        )

        if (!controlsVisible) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .clickable {
                        showControls()
                        controller.toggle()
                    },
            )
        }

        AnimatedVisibility(
            visible = controlsVisible,
            enter = fadeIn(),
            exit = fadeOut(),
        ) {
            PlayerControls(
                controller = controller,
                modifier = Modifier.fillMaxSize(),
                onInteraction = ::showControls,
                onSelectTracks = {
                    controller.pause()
                    trackDialog = it
                    showControls()
                },
            )
        }
    }

    trackDialog?.let { dialog ->
        val tracks = when (dialog) {
            TrackDialog.Audio -> controller.audioTracks
            TrackDialog.Subtitles -> controller.subtitleTracks
        }
        val selected = when (dialog) {
            TrackDialog.Audio -> controller.selectedAudioTrack
            TrackDialog.Subtitles -> controller.selectedSubtitleTrack
        }
        TrackSelectionDialog(
            type = dialog,
            tracks = tracks,
            selected = selected,
            onSelect = { id ->
                when (dialog) {
                    TrackDialog.Audio -> controller.selectAudioTrack(id)
                    TrackDialog.Subtitles -> controller.selectSubtitleTrack(id)
                }
                trackDialog = null
                controller.play()
                showControls()
            },
            onDismiss = {
                trackDialog = null
                controller.play()
                showControls()
            },
        )
    }
}

@Composable
private fun VideoSurface(
    controller: VLCPlayerController,
    modifier: Modifier,
) {
    AndroidView(
        modifier = modifier,
        factory = { context -> SurfaceView(context).also(controller::attach) },
        update = controller::attach,
        onRelease = controller::detach,
    )
}

@Composable
private fun PlayerControls(
    controller: VLCPlayerController,
    modifier: Modifier,
    onInteraction: () -> Unit,
    onSelectTracks: (TrackDialog) -> Unit,
) {
    var sliderPosition by remember { mutableFloatStateOf(controller.position) }
    var seeking by remember { mutableStateOf(false) }
    val seekDescription = stringResource(R.string.vlc_player_seek)

    if (!seeking) sliderPosition = controller.position

    Box(
        modifier = modifier.background(Color.Black.copy(alpha = 0.6f)),
    ) {
        MainControl(
            status = controller.status,
            onClick = {
                controller.toggle()
                onInteraction()
            },
            modifier = Modifier.align(Alignment.Center),
        )

        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .padding(16.dp),
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End,
            ) {
                if (controller.audioTracks.isNotEmpty()) {
                    IconButton(onClick = { onSelectTracks(TrackDialog.Audio) }) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.VolumeUp,
                            contentDescription = stringResource(R.string.vlc_player_audio),
                            tint = Color.White,
                        )
                    }
                }
                if (controller.subtitleTracks.isNotEmpty()) {
                    IconButton(onClick = { onSelectTracks(TrackDialog.Subtitles) }) {
                        Icon(
                            imageVector = Icons.Default.Subtitles,
                            contentDescription = stringResource(R.string.vlc_player_subtitle),
                            tint = Color.White,
                        )
                    }
                }
            }

            Slider(
                value = sliderPosition,
                onValueChange = {
                    if (!seeking) controller.pause()
                    seeking = true
                    sliderPosition = it
                    controller.seekTo(it)
                    onInteraction()
                },
                onValueChangeFinished = {
                    seeking = false
                    controller.play()
                    onInteraction()
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .semantics {
                        contentDescription = seekDescription
                    },
            )

            Row(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = formatPlayerTime(controller.time),
                    color = Color.White,
                    style = MaterialTheme.typography.labelSmall,
                )
                Spacer(modifier = Modifier.weight(1f))
                Text(
                    text = formatPlayerTime(controller.time - controller.length),
                    color = Color.White,
                    style = MaterialTheme.typography.labelSmall,
                )
            }
        }
    }
}

@Composable
private fun MainControl(
    status: PlayerStatus,
    onClick: () -> Unit,
    modifier: Modifier,
) {
    if (status == PlayerStatus.Loading) {
        CircularProgressIndicator(
            modifier = modifier.size(48.dp),
            color = Color.White,
        )
        return
    }

    val icon = when (status) {
        PlayerStatus.Playing -> Icons.Default.Pause
        PlayerStatus.Finished -> Icons.Default.Replay
        PlayerStatus.Error -> Icons.Default.Error
        else -> Icons.Default.PlayArrow
    }
    val label = when (status) {
        PlayerStatus.Playing -> stringResource(R.string.vlc_player_pause)
        PlayerStatus.Finished -> stringResource(R.string.vlc_player_restart)
        PlayerStatus.Error -> stringResource(R.string.vlc_player_error)
        else -> stringResource(R.string.vlc_player_play)
    }

    IconButton(
        onClick = onClick,
        modifier = modifier.size(72.dp),
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            modifier = Modifier.size(48.dp),
            tint = Color.White,
        )
    }
}

@Composable
private fun TrackSelectionDialog(
    type: TrackDialog,
    tracks: List<PlayerTrack>,
    selected: Int?,
    onSelect: (Int) -> Unit,
    onDismiss: () -> Unit,
) {
    val title = when (type) {
        TrackDialog.Audio -> stringResource(R.string.vlc_player_change_audio)
        TrackDialog.Subtitles -> stringResource(R.string.vlc_player_change_subtitle)
    }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            Column {
                for (track in tracks) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onSelect(track.id) }
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        RadioButton(
                            selected = track.id == selected,
                            onClick = { onSelect(track.id) },
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(track.name)
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.vlc_player_cancel))
            }
        },
    )
}

private enum class TrackDialog {
    Audio,
    Subtitles,
}

private const val CONTROL_HIDE_DELAY_MILLIS = 5_000L
