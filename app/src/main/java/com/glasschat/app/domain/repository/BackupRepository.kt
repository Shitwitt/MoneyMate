package com.glasschat.app.domain.repository

import com.glasschat.app.domain.model.BackupResult

interface BackupRepository {
    /** Writes a ZIP (JSON manifest + media files) to a user-chosen SAF URI. */
    suspend fun exportBackup(destinationUri: String): BackupResult

    /** Merges a previously exported ZIP back into the local database. Idempotent by id. */
    suspend fun importBackup(sourceUri: String): BackupResult

    suspend fun deleteAllData()
}
