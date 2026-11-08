package com.glasschat.app.domain.usecase

import com.glasschat.app.domain.model.ChatTemplates
import com.glasschat.app.domain.model.ChatType
import com.glasschat.app.domain.model.ContactDraft
import com.glasschat.app.domain.model.SenderType
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class CreateChatUseCaseTest {

    private lateinit var contacts: FakeContactRepository
    private lateinit var chats: FakeChatRepository
    private lateinit var messages: FakeMessageRepository
    private lateinit var useCase: CreateChatUseCase

    @Before
    fun setUp() {
        contacts = FakeContactRepository()
        chats = FakeChatRepository()
        messages = FakeMessageRepository()
        useCase = CreateChatUseCase(chats, contacts, messages)
    }

    @Test
    fun `existing contact becomes the chat title when none is given`() = runTest {
        val contactId = contacts.createContact(
            ContactDraft(name = "Maya Chen", accentColor = 0xFF4FE3D5),
        )

        val chatId = useCase(
            title = "  ",
            type = ChatType.ONE_TO_ONE,
            existingContactIds = listOf(contactId),
        )

        assertEquals("chat-1", chatId)
        assertEquals("Maya Chen", chats.requests.single().title)
        assertEquals(listOf(contactId), chats.requests.single().participantContactIds)
    }

    @Test
    fun `group without a title falls back to a neutral name`() = runTest {
        val a = contacts.createContact(ContactDraft(name = "Ada", accentColor = 1))
        val b = contacts.createContact(ContactDraft(name = "Bo", accentColor = 2))

        useCase(title = "", type = ChatType.GROUP, existingContactIds = listOf(a, b))

        assertEquals("New group", chats.requests.single().title)
        assertEquals(ChatType.GROUP, chats.requests.single().type)
        assertEquals(2, chats.requests.single().participantContactIds.size)
    }

    @Test
    fun `new contacts are created before the chat`() = runTest {
        val chatId = useCase(
            title = "Draft duo",
            type = ChatType.ONE_TO_ONE,
            newContacts = listOf(ContactDraft(name = "Theo Avery", accentColor = 0xFFC46B)),
        )

        assertEquals(1, contacts.contacts.size)
        assertEquals("Theo Avery", contacts.contacts.values.single().name)
        val participantIds = chats.requests.single().participantContactIds
        assertEquals(1, participantIds.size)
        assertTrue(participantIds.single() in contacts.contacts)
        assertEquals("chat-1", chatId)
    }

    @Test
    fun `duplicate participants are collapsed`() = runTest {
        val id = contacts.createContact(ContactDraft(name = "Ada", accentColor = 1))

        useCase(title = "Solo", type = ChatType.GROUP, existingContactIds = listOf(id, id))

        assertEquals(listOf(id), chats.requests.single().participantContactIds)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `a chat needs at least one participant`() = runTest {
        useCase(title = "Empty", type = ChatType.ONE_TO_ONE)
    }

    @Test
    fun `template seeds are written in the past and start unread`() = runTest {
        val contactId = contacts.createContact(ContactDraft(name = "Maya", accentColor = 3))
        val template = ChatTemplates.byId("weekend")

        val chatId = useCase(
            title = "Weekend",
            type = ChatType.ONE_TO_ONE,
            existingContactIds = listOf(contactId),
            templateId = template.id,
        )

        assertEquals(template.seeds.size, messages.sent.size)
        assertTrue(messages.sent.all { it.chatId == chatId })
        assertEquals(SenderType.CONTACT, messages.sent.first().senderType)
        assertEquals(contactId, messages.sent.first().senderContactId)
        assertEquals(SenderType.ME, messages.sent[1].senderType)
        assertTrue(messages.sent.zipWithNext().all { (a, b) -> a.createdAt!! <= b.createdAt!! })
        assertTrue(chats.unreadChats.contains(chatId))
    }

    @Test
    fun `blank template leaves the chat empty but readable`() = runTest {
        val contactId = contacts.createContact(ContactDraft(name = "Bo", accentColor = 4))

        val chatId = useCase(
            title = "",
            type = ChatType.ONE_TO_ONE,
            existingContactIds = listOf(contactId),
            templateId = "blank",
        )

        assertTrue(messages.sent.isEmpty())
        assertTrue(chatId !in chats.unreadChats)
    }
}
