package app.velomine.velomine

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.workDataOf
import java.util.concurrent.TimeUnit

/** Schedules the upload worker. Replacing the unique work keeps the latest server address. */
object RideUploadScheduler {
    private const val WORK_NAME = "velomine-ride-upload"

    fun schedule(context: Context, serverUrl: String) {
        val request = OneTimeWorkRequestBuilder<RideUploadWorker>()
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build(),
            )
            .setInputData(workDataOf(RideUploadWorker.KEY_SERVER_URL to serverUrl))
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
            .build()

        // A worker that is running may have started before a new ride was ready, so chain the new work after it.
        // Each run exits at once when there is nothing left to upload.
        WorkManager.getInstance(context).enqueueUniqueWork(
            WORK_NAME,
            ExistingWorkPolicy.APPEND_OR_REPLACE,
            request,
        )
    }
}
