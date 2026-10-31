package com.example.secret_word_society

import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.SystemClock
import android.util.Log

/** In-memory foreground signal; no alarms, services or wake-lock permission. */
object RoundSignal {
    private var token: String? = null
    private var deadline = 0L
    private var consumed = false
    private var player: MediaPlayer? = null
    private var foreground = false
    private const val TAG = "RoundSignal"

    val running: Boolean
        get() = token != null && !consumed && SystemClock.elapsedRealtime() < deadline

    val keepingScreenOn: Boolean
        get() = running || player != null

    fun setForeground(visible: Boolean) {
        foreground = visible
        if (!visible) {
            player?.let { release(it) }
        } else if (token != null && SystemClock.elapsedRealtime() >= deadline) {
            // A round that expired while interrupted must never sound on return.
            consumed = true
        }
    }

    fun arm(roundToken: String, deadlineMillis: Long) {
        cancel()
        token = roundToken
        deadline = SystemClock.elapsedRealtime() +
            (deadlineMillis - System.currentTimeMillis())
        consumed = false
    }

    fun cancel() {
        token = null
        consumed = true
        player?.release()
        player = null
    }

    fun finish(context: Context, roundToken: String?, audible: Boolean, onPlaybackEnded: () -> Unit) {
        if (roundToken == null || token != roundToken || consumed) return
        val lateness = SystemClock.elapsedRealtime() - deadline
        if (lateness < 0) return
        // Consume even a muted/missed signal. Returning to the app never replays it.
        consumed = true
        if (!audible || !foreground) return
        if (lateness > 2000) {
            Log.i(TAG, "expired")
            return
        }
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val notifications = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (audio.ringerMode != AudioManager.RINGER_MODE_NORMAL ||
            audio.getStreamVolume(AudioManager.STREAM_MUSIC) == 0 ||
            notifications.currentInterruptionFilter != NotificationManager.INTERRUPTION_FILTER_ALL) {
            Log.i(TAG, "suppressed")
            return
        }
        try {
            val sound = MediaPlayer()
            player = sound
            sound.setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
            context.resources.openRawResourceFd(R.raw.round_end).use { asset ->
                sound.setDataSource(asset.fileDescriptor, asset.startOffset, asset.length)
            }
            sound.setOnCompletionListener {
                release(it)
                Log.i(TAG, "completed")
                onPlaybackEnded()
            }
            sound.setOnErrorListener { media, _, _ ->
                release(media)
                onPlaybackEnded()
                true
            }
            sound.prepare()
            sound.start()
            Log.i(TAG, "played")
        } catch (_: Exception) {
            player?.let { release(it) }
            Log.w(TAG, "audio_unavailable")
        }
    }

    private fun release(sound: MediaPlayer) {
        if (player === sound) player = null
        sound.release()
    }
}
