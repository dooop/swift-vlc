package org.videolan.vlcplayer.sample

import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.ComposeView
import org.videolan.vlcplayer.VLCPlayer

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(
            ComposeView(this).apply {
                setContent {
                    MaterialTheme {
                        VLCPlayerSampleApp()
                    }
                }
            },
        )
    }
}

@Composable
private fun VLCPlayerSampleApp() {
    var urlText by rememberSaveable { mutableStateOf(SAMPLE_VIDEO_URL) }
    var playingUrl by rememberSaveable { mutableStateOf<String?>(null) }
    var validationError by rememberSaveable { mutableStateOf<String?>(null) }

    fun play() {
        val candidate = urlText.trim()
        val scheme = Uri.parse(candidate).scheme?.lowercase()
        if (candidate.isEmpty() || scheme !in SUPPORTED_SCHEMES) {
            validationError = "Enter a complete HTTP(S), RTSP, RTMP, file, or content URI."
            return
        }
        validationError = null
        playingUrl = candidate
    }

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background,
    ) {
        val currentUrl = playingUrl
        if (currentUrl == null) {
            Column(
                modifier = Modifier
                    .safeDrawingPadding()
                    .padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                Text(
                    text = "VLC Player",
                    style = MaterialTheme.typography.headlineMedium,
                )
                Text(
                    text = "Enter a direct media or stream URL. The sample URL is ready to play.",
                    style = MaterialTheme.typography.bodyLarge,
                )
                OutlinedTextField(
                    value = urlText,
                    onValueChange = {
                        urlText = it
                        validationError = null
                    },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("Media URL") },
                    supportingText = validationError?.let { message ->
                        { Text(message) }
                    },
                    isError = validationError != null,
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Go),
                    keyboardActions = KeyboardActions(onGo = { play() }),
                )
                Button(
                    onClick = { play() },
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text("Play with VLC")
                }
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .safeDrawingPadding(),
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 8.dp),
                ) {
                    TextButton(onClick = { playingUrl = null }) {
                        Text("Change URL")
                    }
                    Text(
                        text = currentUrl,
                        modifier = Modifier
                            .weight(1f)
                            .padding(12.dp),
                        maxLines = 1,
                        style = MaterialTheme.typography.bodySmall,
                    )
                }
                VLCPlayer(
                    url = Uri.parse(currentUrl),
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                )
            }
        }
    }
}

private val SUPPORTED_SCHEMES = setOf("http", "https", "rtsp", "rtmp", "file", "content")
private const val SAMPLE_VIDEO_URL =
    "https://test-videos.co.uk/vids/bigbuckbunny/mkv/1080/Big_Buck_Bunny_1080_10s_1MB.mkv"
