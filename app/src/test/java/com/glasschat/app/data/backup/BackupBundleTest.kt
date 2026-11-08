package com.glasschat.app.data.backup

import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class BackupBundleTest {

    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    @Test
    fun `bundle round trips through json`() {
        val bundle = BackupBundle(
            exportedAt = 1_700_000_000_000,
            appVersion = "1.0.0",
            contacts = listOf(
                ContactDto(
                    id = "c1",
                    name = "Maya Chen",
                    accentColor = 0xFF4FE3D5,
                    bio = "Photographer",
                    phoneLabel = "Mobile",
                    notes = "",
                    isFavorite = true,
                    isBlocked = false,
                    createdAt = 1_700_000_000_000,
                ),
            ),
        )
        val encoded = json.encodeToString(BackupBundle.serializer(), bundle)
        assertTrue(encoded.contains(BackupBundle.FORMAT))
        val decoded = json.decodeFromString(BackupBundle.serializer(), encoded)
        assertEquals(bundle.contacts, decoded.contacts)
        assertEquals(BackupBundle.VERSION, decoded.version)
        assertEquals(1_700_000_000_000, decoded.exportedAt)
    }

    @Test
    fun `unknown keys from a newer backup are ignored`() {
        val payload = """
            {
              "format": "glasschat-backup",
              "version": 99,
              "exportedAt": 1,
              "appVersion": "9.9.9",
              "contacts": [],
              "futureField": {"nested": true}
            }
        """.trimIndent()
        val decoded = json.decodeFromString(BackupBundle.serializer(), payload)
        assertEquals(99, decoded.version)
        assertTrue(decoded.contacts.isEmpty())
    }
}
