package com.example.aura_music_kit

import android.content.ContentResolver
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.audiofx.Equalizer
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Size
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream

class AuraMusicKitPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var contentResolver: ContentResolver
    private var equalizer: Equalizer? = null
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding
        
        context = flutterPluginBinding.applicationContext
        contentResolver = context.contentResolver
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.aura_music_kit/channel")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getMusicFiles" -> {
                // Run in a background thread to avoid blocking the UI thread
                Thread {
                    val musicList = queryMusicFiles()
                    // Post the result back to the main thread using a Handler
                    Handler(Looper.getMainLooper()).post {
                        result.success(musicList)
                    }
                }.start()
            }
            "initEqualizer" -> {
                val audioSessionId = call.argument<Int>("audioSessionId")
                if (audioSessionId != null) {
                    try {
                        equalizer?.release()
                        equalizer = Equalizer(0, audioSessionId).apply { enabled = true }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("EQUALIZER_ERROR", "Failed to initialize equalizer", e.toString())
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Audio Session ID cannot be null", null)
                }
            }
            "getEqualizerSettings" -> {
                equalizer?.let { eq ->
                    val settings = mapOf(
                        "numberOfBands" to eq.numberOfBands,
                        "minDecibels" to eq.bandLevelRange[0],
                        "maxDecibels" to eq.bandLevelRange[1],
                        "centerFrequencies" to (0 until eq.numberOfBands).map {
                            eq.getCenterFreq(it.toShort())
                        }
                    )
                    result.success(settings)
                } ?: result.error("EQUALIZER_NOT_INIT", "Equalizer is not initialized", null)
            }
            "setBandLevel" -> {
                val band = call.argument<Int>("band")
                val level = call.argument<Int>("level")
                if (equalizer != null && band != null && level != null) {
                    equalizer!!.setBandLevel(band.toShort(), level.toShort())
                    result.success(true)
                } else {
                    result.error("EQUALIZER_ERROR", "Failed to set band level", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun queryMusicFiles(): List<Map<String, Any?>> {
        val musicList = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA
        )
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            null,
            sortOrder
        )?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val durationColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val pathColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idColumn)
                val artwork = getArtwork(id)
                val songMap = mapOf(
                    "id" to id.toInt(),
                    "title" to cursor.getString(titleColumn),
                    "artist" to cursor.getString(artistColumn),
                    "duration" to cursor.getInt(durationColumn),
                    "path" to cursor.getString(pathColumn),
                    "artwork" to artwork
                )
                musicList.add(songMap)
            }
        }
        return musicList
    }

    private fun getArtwork(songId: Long): ByteArray? {
        return try {
            val artworkUri = Uri.withAppendedPath(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, songId.toString())
            val bitmap = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                contentResolver.loadThumbnail(artworkUri, Size(200, 200), null)
            } else {
                // Fallback for older versions
                BitmapFactory.decodeStream(contentResolver.openInputStream(artworkUri))
            }
            val stream = ByteArrayOutputStream()
            bitmap?.compress(Bitmap.CompressFormat.JPEG, 80, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            null
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        equalizer?.release()
        equalizer = null
    }
}
