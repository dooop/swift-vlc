package org.videolan.vlcplayer

import org.junit.Assert.assertEquals
import org.junit.Test

class TrackListTest {
    @Test
    fun addsDisabledPlaceholderWhenTracksExist() {
        val tracks = listOf(PlayerTrack(2, "English"), PlayerTrack(3, "German"))

        val result = buildTrackList(tracks, disabledId = -1, disabledLabel = "Disable")

        assertEquals(
            listOf(PlayerTrack(-1, "Disable"), PlayerTrack(2, "English"), PlayerTrack(3, "German")),
            result,
        )
    }

    @Test
    fun leavesEmptyTrackListEmpty() {
        val result = buildTrackList(emptyList(), disabledId = -1, disabledLabel = "Disable")

        assertEquals(emptyList<PlayerTrack>(), result)
    }

    @Test
    fun doesNotDuplicateAnExistingDisabledEntry() {
        val tracks = listOf(PlayerTrack(-1, "Disable"), PlayerTrack(2, "English"))

        val result = buildTrackList(tracks, disabledId = -1, disabledLabel = "Disable")

        assertEquals(tracks, result)
    }
}
