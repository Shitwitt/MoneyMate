package com.glasschat.app.data.mapper

import com.glasschat.app.data.local.db.entity.ChatEntity
import com.glasschat.app.data.local.db.entity.ContactEntity
import com.glasschat.app.domain.model.ChatType
import com.glasschat.app.domain.model.Contact
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class MappersTest {

    private val contact = Contact(
        id = "c1",
        name = "Maya Chen",
        avatarUri = null,
        accentColor = 0xFF4FE3D5,
        bio = "Photographer",
        phoneLabel = "Mobile",
        notes = "Met at the studio",
        isFavorite = true,
        isBlocked = false,
        createdAt = 1_700_000_000_000,
    )

    @Test
    fun `contact survives an entity round trip`() {
        val restored = contact.toEntity().toDomain()
        assertEquals(contact, restored)
    }

    @Test
    fun `contact entity keeps every field`() {
        val entity: ContactEntity = contact.toEntity()
        assertEquals("Maya Chen", entity.name)
        assertEquals("Photographer", entity.bio)
        assertEquals("Mobile", entity.phoneLabel)
        assertEquals("Met at the studio", entity.notes)
        assertEquals(0xFF4FE3D5, entity.accentColor)
        assertEquals(true, entity.isFavorite)
        assertEquals(false, entity.isBlocked)
    }

    @Test
    fun `chat entity maps null overrides as inherit`() {
        val entity = ChatEntity(
            id = "chat1",
            title = "Studio trio",
            type = ChatType.GROUP,
            createdAt = 10,
            updatedAt = 20,
            draft = "half written",
        )
        val chat = entity.toDomain()
        assertEquals("chat1", chat.id)
        assertEquals(ChatType.GROUP, chat.type)
        assertNull(chat.wallpaper)
        assertNull(chat.accentColor)
        assertNull(chat.bubbleColorMe)
        assertEquals("half written", chat.draft)
        assertEquals(false, chat.isArchived)
    }
}
