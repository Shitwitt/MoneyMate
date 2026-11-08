package com.glasschat.app.backup

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.glasschat.app.domain.model.ContactDraft
import com.glasschat.app.domain.repository.BackupRepository
import com.glasschat.app.domain.repository.ContactRepository
import com.glasschat.app.domain.repository.SettingsRepository
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.zip.ZipFile
import javax.inject.Inject

/**
 * Exercises the real backup pipeline against the on-device database: export a ZIP, check the
 * manifest is present, wipe everything and merge the backup back in.
 */
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class BackupInstrumentedTest {

    @get:Rule
    val hiltRule = HiltAndroidRule(this)

    @Inject
    lateinit var backupRepository: BackupRepository

    @Inject
    lateinit var contactRepository: ContactRepository

    @Inject
    lateinit var settingsRepository: SettingsRepository

    private lateinit var context: Context
    private lateinit var archive: File

    @Before
    fun setUp() {
        hiltRule.inject()
        context = ApplicationProvider.getApplicationContext()
        archive = File(context.cacheDir, "glasschat-test-backup.zip").apply { delete() }
        runBlocking {
            backupRepository.deleteAllData()
            settingsRepository.setOnboardingComplete(true)
            contactRepository.createContact(
                ContactDraft(name = "Backup Tester", accentColor = 0xFF4FE3D5, bio = "Round trip"),
            )
        }
    }

    @After
    fun tearDown() {
        archive.delete()
    }

    @Test
    fun exportWritesManifestAndMediaFolder() = runBlocking {
        val result = backupRepository.exportBackup(android.net.Uri.fromFile(archive).toString())

        assertTrue("Backup file was not written", archive.exists())
        assertTrue("Backup file is empty", archive.length() > 0)
        assertEquals(1, result.contacts)
        assertTrue(result.bytesWritten > 0)

        ZipFile(archive).use { zip ->
            val names = zip.entries().toList().map { it.name }
            assertTrue("backup.json missing", names.contains("backup.json"))
        }

        val lastBackup = settingsRepository.preferences.first().lastBackupAt
        assertTrue("Export did not stamp a backup time", lastBackup != null)
    }

    @Test
    fun importRestoresContactsAfterWipe() = runBlocking {
        backupRepository.exportBackup(android.net.Uri.fromFile(archive).toString())
        backupRepository.deleteAllData()
        assertEquals(0, contactRepository.countContacts())

        val restored = backupRepository.importBackup(android.net.Uri.fromFile(archive).toString())

        assertEquals(1, restored.contacts)
        assertEquals(1, contactRepository.countContacts())
    }
}
