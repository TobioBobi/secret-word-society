package com.example.secret_word_society

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.SystemClock
import android.util.Log

/** Only an in-memory round may sound: process death also discards the game session. */
object RoundSignal {
    private var token: String? = null
    private var deadline = 0L
    private var consumed = false
    private var player: MediaPlayer? = null
    private const val TAG = "RoundSignal"

    private fun alarm(context: Context) =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun backgroundAllowed(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarm(context).canScheduleExactAlarms()

    private fun pending(context: Context, roundToken: String? = null): PendingIntent =
        PendingIntent.getBroadcast(context, 28,
            Intent(context, RoundSignalReceiver::class.java).putExtra("token", roundToken),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    fun arm(context: Context, roundToken: String, deadlineMillis: Long) {
        cancel(context)
        token = roundToken
        deadline = SystemClock.elapsedRealtime() +
            (deadlineMillis - System.currentTimeMillis())
        consumed = false
        if (backgroundAllowed(context)) {
            try {
                alarm(context).setExactAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP, deadline, pending(context, roundToken))
            } catch (_: SecurityException) {
                // Permission can be revoked between checking and scheduling.
                Log.i(TAG, "background_unavailable")
            }
        }
    }

    fun cancel(context: Context) {
        token = null
        consumed = true
        alarm(context).cancel(pending(context))
        player?.release()
        player = null
    }

    fun finish(context: Context, roundToken: String?) {
        if (roundToken == null || token != roundToken || consumed) return
        val lateness = SystemClock.elapsedRealtime() - deadline
        if (lateness < 0) return
        // Consume even a muted/missed signal. Returning to the app never replays it.
        consumed = true
        alarm(context).cancel(pending(context))
        if (lateness > 2000) {
            Log.i(TAG, "expired")
            return
        }
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val notifications = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (audio.ringerMode != AudioManager.RINGER_MODE_NORMAL ||
            audio.getStreamVolume(AudioManager.STREAM_NOTIFICATION) == 0 ||
            notifications.currentInterruptionFilter != NotificationManager.INTERRUPTION_FILTER_ALL) {
            Log.i(TAG, "suppressed")
            return
        }
        try {
            val sound = MediaPlayer()
            player = sound
            sound.setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
            sound.setWakeMode(context, android.os.PowerManager.PARTIAL_WAKE_LOCK)
            context.resources.openRawResourceFd(R.raw.round_end).use { asset ->
                sound.setDataSource(asset.fileDescriptor, asset.startOffset, asset.length)
            }
            sound.setOnCompletionListener { release(it) }
            sound.setOnErrorListener { media, _, _ -> release(media); true }
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

class RoundSignalReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        RoundSignal.finish(context.applicationContext, intent.getStringExtra("token"))
    }
}
