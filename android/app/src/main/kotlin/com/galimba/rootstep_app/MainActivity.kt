package com.galimba.rootstep_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.galimba.rootstep/live_activity"
    private val NOTIFICATION_ID = 888
    private val CHANNEL_ID = "rootstep_run_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startActivity", "updateActivity" -> {
                    val time = call.argument<String>("time") ?: "00:00"
                    val distance = call.argument<Double>("distance") ?: 0.0
                    val pace = call.argument<String>("pace") ?: "0'00\""
                    
                    showOrUpdateNotification(time, distance, pace)
                    result.success(null)
                }
                "stopActivity" -> {
                    cancelNotification()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun showOrUpdateNotification(time: String, distance: Double, pace: String) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Bind the XML layout to the RemoteViews object
        val customView = RemoteViews(packageName, R.layout.custom_notification)
        
        // Update text fields
        customView.setTextViewText(R.id.time_text, time)
        customView.setTextViewText(R.id.distance_text, String.format("%.2f km", distance / 1000))
        customView.setTextViewText(R.id.pace_text, pace)
        
        // Update the "Root" progress bar (calculating modulo 10000m to loop the growth)
        val progressValue = (distance % 10000).toInt() 
        customView.setProgressBar(R.id.root_progress, 10000, progressValue, false)

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_compass) // Fallback icon
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(customView)
            .setCustomBigContentView(customView)
            .setOngoing(true) // Prevents the user from swiping it away
            .setPriority(NotificationCompat.PRIORITY_HIGH)

        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }

    private fun cancelNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(NOTIFICATION_ID)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Running Tracker"
            val descriptionText = "Shows active run statistics on lock screen"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setSound(null, null) // Silent notification update
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}