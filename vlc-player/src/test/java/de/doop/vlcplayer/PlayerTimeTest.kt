package de.doop.vlcplayer

import org.junit.Assert.assertEquals
import org.junit.Test

class PlayerTimeTest {
    @Test
    fun formatsShortDurations() {
        assertEquals("00:00", formatPlayerTime(0L))
        assertEquals("01:05", formatPlayerTime(65_000L))
        assertEquals("-00:09", formatPlayerTime(-9_900L))
    }

    @Test
    fun includesHoursWhenNeeded() {
        assertEquals("01:02:03", formatPlayerTime(3_723_000L))
    }
}
