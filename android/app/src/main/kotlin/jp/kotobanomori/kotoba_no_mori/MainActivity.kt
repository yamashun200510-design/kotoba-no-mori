package jp.kotobanomori.kotoba_no_mori

import android.animation.ValueAnimator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.FlutterInjector
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.SoundPool
import android.media.AudioManager
import android.content.Context
import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.view.animation.DecelerateInterpolator
import android.util.Log

class MainActivity : FlutterActivity() {
    private var pool: SoundPool? = null
    private val sounds = mutableMapOf<String, Int>()
    private val ready = mutableSetOf<Int>()
    private var stream = 0
    private var pending: String? = null
    private var foreground = true
    private var musicPlayer: MediaPlayer? = null
    private var musicTrack: String? = null
    private var musicPrepared = false
    private var musicVolume = 0f
    private var musicFade: ValueAnimator? = null
    private val musicTargetVolume = .35f

    private fun stopSound() {
        pending = null
        if (stream != 0) pool?.stop(stream)
        stream = 0
    }

    private fun playSound(name: String): Boolean {
        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (!foreground || audio.ringerMode != AudioManager.RINGER_MODE_NORMAL ||
            audio.getStreamVolume(AudioManager.STREAM_MUSIC) == 0) return false
        val id = sounds[name] ?: return false
        if (!ready.contains(id)) {
            pending = name
            return false
        }
        stopSound()
        stream = pool?.play(id, .65f, .65f, 1, 0, 1f) ?: 0
        Log.d("KotobaSound", "$name: stream=$stream")
        return stream != 0
    }

    private fun fadeMusic(player: MediaPlayer, from: Float, to: Float, onEnd: () -> Unit) {
        musicFade?.cancel()
        val animator = ValueAnimator.ofFloat(from, to).apply {
            duration = 480
            interpolator = DecelerateInterpolator()
        }
        musicFade = animator
        animator.addUpdateListener {
            val volume = it.animatedValue as Float
            if (musicPlayer === player) musicVolume = volume
            try {
                player.setVolume(volume, volume)
            } catch (_: IllegalStateException) {
                // The player may have failed while a fade was in progress.
            }
        }
        animator.addListener(object : AnimatorListenerAdapter() {
            override fun onAnimationEnd(animation: Animator) {
                if (musicFade === animator) musicFade = null
                onEnd()
            }
        })
        animator.start()
    }

    private fun changeMusic(track: String?) {
        if (track != null && track !in setOf("home", "puzzle")) {
            Log.w("KotobaMusic", "Unknown BGM track: $track")
            return
        }
        if (track == musicTrack) {
            val player = musicPlayer
            if (track != null && player != null && musicPrepared && foreground) {
                if (!player.isPlaying) player.start()
                if (musicVolume < musicTargetVolume) {
                    fadeMusic(player, musicVolume, musicTargetVolume) {}
                }
            }
            return
        }
        musicTrack = track
        val old = musicPlayer
        if (old == null) {
            if (track != null) startMusic(track)
            return
        }
        if (!musicPrepared) {
            musicPlayer = null
            musicPrepared = false
            musicVolume = 0f
            try { old.release() } catch (_: IllegalStateException) {}
            if (track != null) startMusic(track)
            return
        }
        fadeMusic(old, musicVolume, 0f) {
            if (musicPlayer === old) {
                musicPlayer = null
                musicPrepared = false
                musicVolume = 0f
                try { old.release() } catch (_: IllegalStateException) {}
            }
            val next = musicTrack
            if (next != null) startMusic(next)
        }
    }

    private fun startMusic(track: String) {
        val assetPath = when (track) {
            "home" -> "assets/music/home_loop.wav"
            "puzzle" -> "assets/music/puzzle_loop.wav"
            else -> return
        }
        val player = MediaPlayer()
        musicPlayer = player
        musicPrepared = false
        musicVolume = 0f
        try {
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            player.isLooping = true
            player.setVolume(0f, 0f)
            val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(assetPath)
            assets.openFd(key).use { descriptor ->
                player.setDataSource(
                    descriptor.fileDescriptor,
                    descriptor.startOffset,
                    descriptor.length
                )
            }
            player.setOnPreparedListener { prepared ->
                if (musicPlayer !== prepared || musicTrack != track) {
                    prepared.release()
                    return@setOnPreparedListener
                }
                musicPrepared = true
                if (foreground) {
                    prepared.start()
                    Log.d("KotobaMusic", "BGM started: $track")
                    fadeMusic(prepared, 0f, musicTargetVolume) {}
                }
            }
            player.setOnErrorListener { failed, what, extra ->
                Log.e("KotobaMusic", "BGM failed ($track): $what/$extra")
                if (musicPlayer === failed) {
                    musicPlayer = null
                    musicTrack = null
                    musicPrepared = false
                    musicVolume = 0f
                }
                failed.release()
                true
            }
            player.prepareAsync()
        } catch (error: Exception) {
            Log.w("KotobaMusic", "Skipping unavailable BGM: $assetPath", error)
            if (musicPlayer === player) {
                musicPlayer = null
                musicTrack = null
                musicPrepared = false
                musicVolume = 0f
            }
            try { player.release() } catch (_: IllegalStateException) {}
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val player = SoundPool.Builder().setMaxStreams(1).setAudioAttributes(
            AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()).build()
        pool = player
        player.setOnLoadCompleteListener { _, id, status ->
            if (status == 0) {
                ready.add(id)
                val cue = pending
                if (cue != null && sounds[cue] == id) playSound(cue)
            }
        }
        for (name in listOf("key", "wrong", "win", "reward", "buy", "stage", "wind")) {
            val asset = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset("assets/sounds/$name.wav")
            // Sound assets are optional at startup. A missing/corrupt sound must
            // never prevent the game from opening (for example after an older
            // or partially packaged APK is installed).
            try {
                assets.openFd(asset).use { sounds[name] = player.load(it, 1) }
            } catch (error: Exception) {
                Log.w("KotobaSound", "Skipping unavailable sound asset: $asset", error)
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kotoba_no_mori/sounds")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "stop" -> { stopSound(); result.success(null) }
                    "music" -> { changeMusic(call.arguments as? String); result.success(null) }
                    "play" -> result.success(playSound(call.arguments as? String ?: ""))
                    else -> result.notImplemented()
                }
            }
    }
    override fun onPause() {
        foreground = false
        stopSound()
        musicFade?.cancel()
        musicFade = null
        if (musicPrepared) {
            try { if (musicPlayer?.isPlaying == true) musicPlayer?.pause() }
            catch (_: IllegalStateException) {}
        }
        super.onPause()
    }
    override fun onResume() {
        super.onResume()
        foreground = true
        if (musicPrepared) {
            try {
                musicPlayer?.let { player ->
                    if (!player.isPlaying) player.start()
                    if (musicVolume < musicTargetVolume) {
                        fadeMusic(player, musicVolume, musicTargetVolume) {}
                    }
                }
            } catch (_: IllegalStateException) {}
        }
    }
    override fun onDestroy() {
        musicFade?.cancel()
        musicPlayer?.release()
        musicPlayer = null
        musicPrepared = false
        pool?.release()
        pool = null
        super.onDestroy()
    }
}
